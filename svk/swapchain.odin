package svk

import "core:fmt"
import "core:math"

import "vendor:glfw"
import vk "vendor:vulkan"

Swapchain_Config :: struct {
	format:       vk.Format,
	color_space:  vk.ColorSpaceKHR,
	present_mode: vk.PresentModeKHR,
}

Swapchain :: struct {
	handle:               vk.SwapchainKHR,
	//
	format:               vk.SurfaceFormatKHR,
	depth_format:         vk.Format,
	present_mode:         vk.PresentModeKHR,
	extent:               vk.Extent2D,
	//
	image_count:          u32,
	images:               []vk.Image,
	image_views:          []vk.ImageView,
	depth_images:         []vk.Image,
	depth_image_views:    []vk.ImageView,
	depth_image_memories: []vk.DeviceMemory,
	// don't modify
	_old_swapchain:       vk.SwapchainKHR,
}

create_swapchain :: proc(ctx: ^Context, config: Swapchain_Config) -> (swapchain: Swapchain) {
	recreate_swapchain(ctx, &swapchain, config)
	return
}

recreate_swapchain :: proc(ctx: ^Context, swapchain: ^Swapchain, config: Swapchain_Config) {
	swapchain._old_swapchain = swapchain.handle

	vk.DeviceWaitIdle(ctx.device)

	swapchain.format, swapchain.depth_format = choose_surface_formats(
		config,
		ctx.swapchain_support.surface_formats,
		ctx.physical_device,
	)
	swapchain.present_mode = choose_present_mode(config, ctx.swapchain_support.present_modes)
	swapchain.extent = choose_extent(ctx.swapchain_support.capabilities, ctx.window.handle)

	create_images(swapchain, ctx.device)
	create_depth_resources(ctx, swapchain)
}

@(private = "file")
choose_surface_formats :: proc(
	config: Swapchain_Config,
	formats: []vk.SurfaceFormatKHR,
	physical_device: vk.PhysicalDevice,
) -> (
	image_format: vk.SurfaceFormatKHR,
	depth_format: vk.Format,
) {
	found := false
	for format in formats {
		if format.format == config.format && format.colorSpace == config.color_space {
			image_format = format
			found = true
			break
		}
	}

	if !found {
		image_format = formats[0]

		print_warning_prefix()
		fmt.printfln(
			"The requested swapchain format and color space combination is not available, defaulting to the first format in the array (format: %v, color space: %v)",
			image_format.format,
			image_format.colorSpace,
		)
	}

	found = false
	depth_formats :: [3]vk.Format{.D32_SFLOAT, .D32_SFLOAT_S8_UINT, .D24_UNORM_S8_UINT}

	for format in depth_formats {
		format_properties: vk.FormatProperties
		vk.GetPhysicalDeviceFormatProperties(physical_device, format, &format_properties)

		if .DEPTH_STENCIL_ATTACHMENT in format_properties.optimalTilingFeatures {
			depth_format = format
			found = true
			break
		}
	}

	if !found {
		panic(
			"None of the formats .D32_SFLOAT, .D32_SFLOAT_S8_UINT, .D24_UNORM_S8_UINT are supported",
		)
	}

	return
}

@(private = "file")
choose_present_mode :: proc(
	config: Swapchain_Config,
	modes: []vk.PresentModeKHR,
) -> vk.PresentModeKHR {
	for mode in modes {
		if mode == config.present_mode {
			return mode
		}
	}

	print_warning_prefix()
	fmt.println("The requested swapchain present mode is not available, defaulting to .FIFO")

	return .FIFO
}

@(private = "file")
choose_extent :: proc(
	capabilities: vk.SurfaceCapabilitiesKHR,
	window: glfw.WindowHandle,
) -> vk.Extent2D {
	if capabilities.currentExtent.width != ~u32(0) {
		return capabilities.currentExtent
	}

	width, height := glfw.GetFramebufferSize(window)
	extent := vk.Extent2D{u32(width), u32(height)}

	extent.width = math.clamp(
		extent.width,
		capabilities.minImageExtent.width,
		capabilities.maxImageExtent.width,
	)

	extent.height = math.clamp(
		extent.height,
		capabilities.minImageExtent.height,
		capabilities.maxImageExtent.height,
	)

	return extent
}

@(private = "file")
create_images :: proc(swapchain: ^Swapchain, device: vk.Device) {
	vk.GetSwapchainImagesKHR(device, swapchain.handle, &swapchain.image_count, nil)
	assert(swapchain.image_count != 0, "The swapchain image count is 0")

	swapchain.images = make([]vk.Image, swapchain.image_count)

	result := vk.GetSwapchainImagesKHR(device, swapchain.handle, nil, raw_data(swapchain.images))
	if result != .SUCCESS {
		fmt.panicf("Failed to get the swapchain images (result: %v)", result)
	}

	view_info := vk.ImageViewCreateInfo {
		sType = .IMAGE_VIEW_CREATE_INFO,
		viewType = .D2,
		format = .R8G8B8A8_UNORM,
		components = vk.ComponentMapping{.R, .G, .B, .A},
		subresourceRange = vk.ImageSubresourceRange {
			aspectMask = {.COLOR},
			baseArrayLayer = 0,
			layerCount = 1,
			baseMipLevel = 0,
			levelCount = 1,
		},
	}

	swapchain.image_views = make([]vk.ImageView, swapchain.image_count)

	for image, i in swapchain.images {
		view_info.image = image

		result = vk.CreateImageView(device, &view_info, nil, &swapchain.image_views[i])
		if result != .SUCCESS {
			fmt.panicf("Failed to create an image view (result: %v)", result)
		}
	}
}

@(private = "file")
create_depth_resources :: proc(ctx: ^Context, swapchain: ^Swapchain) {
	image_info := vk.ImageCreateInfo {
		sType                 = .IMAGE_CREATE_INFO,
		imageType             = .D2,
		format                = .R8G8B8A8_UNORM,
		extent                = {swapchain.extent.width, swapchain.extent.height, 1},
		mipLevels             = 1,
		arrayLayers           = 1,
		samples               = {._1},
		tiling                = .OPTIMAL,
		usage                 = {.SAMPLED},
		sharingMode           = .EXCLUSIVE,
		queueFamilyIndexCount = ctx.graphics_queue == ctx.present_queue ? 1 : 2,
		pQueueFamilyIndices   = raw_data(
			[]u32{ctx.graphics_queue.family, ctx.present_queue.family},
		),
		initialLayout         = .UNDEFINED,
	}

	view_info := vk.ImageViewCreateInfo {
		sType = .IMAGE_VIEW_CREATE_INFO,
		viewType = .D2,
		format = swapchain.depth_format,
		components = vk.ComponentMapping{.R, .G, .B, .A},
		subresourceRange = vk.ImageSubresourceRange {
			aspectMask = {.DEPTH},
			baseArrayLayer = 0,
			layerCount = 1,
			baseMipLevel = 0,
			levelCount = 1,
		},
	}

	swapchain.depth_images = make([]vk.Image, swapchain.image_count)
	swapchain.depth_image_views = make([]vk.ImageView, swapchain.image_count)

	for i in 0 ..< swapchain.image_count {
		result := vk.CreateImage(ctx.device, &image_info, nil, &swapchain.depth_images[i])
		if result != .SUCCESS {
			fmt.panicf("Failed to create a swapchain depth image (result: %v)", result)
		}

		image := swapchain.depth_images[i]

		mem_requirements: vk.MemoryRequirements
		vk.GetImageMemoryRequirements(ctx.device, image, &mem_requirements)

		alloc_info := vk.MemoryAllocateInfo {
			sType           = .MEMORY_ALLOCATE_INFO,
			allocationSize  = mem_requirements.size,
			memoryTypeIndex = find_memory_type(
				mem_requirements.memoryTypeBits,
				{.DEVICE_LOCAL},
				ctx.physical_device,
			),
		}

		result = vk.AllocateMemory(
			ctx.device,
			&alloc_info,
			nil,
			&swapchain.depth_image_memories[i],
		)
		if result != .SUCCESS {
			fmt.panicf("Failed to create a swapchain depth memory (result: %v)")
		}

		memory := swapchain.depth_image_memories[i]

		result = vk.BindImageMemory(ctx.device, image, memory, 0)
		if result != .SUCCESS {
			fmt.panicf("Failed to bind a swapchain depth memory (result: %v)")
		}

		view_info.image = swapchain.depth_images[i]

		result = vk.CreateImageView(ctx.device, &view_info, nil, &swapchain.depth_image_views[i])
		if result != .SUCCESS {
			fmt.panicf("Failed to create a swapchain depth image view (result: %v)", result)
		}
	}
}

@(private = "file")
find_memory_type :: proc(
	type_filter: u32,
	properties: vk.MemoryPropertyFlags,
	physical_device: vk.PhysicalDevice,
) -> u32 {
	mem_properties: vk.PhysicalDeviceMemoryProperties
	vk.GetPhysicalDeviceMemoryProperties(physical_device, &mem_properties)

	for i in 0 ..< mem_properties.memoryTypeCount {
		if (type_filter) & (1 << i) != 0 &&
		   (mem_properties.memoryTypes[i].propertyFlags & properties) == properties {
			return i
		}
	}

	panic("Failed to find a supported memory type")
}

