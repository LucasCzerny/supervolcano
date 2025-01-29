package svk

import "core:fmt"
import "core:mem"
import "core:slice"

import vk "vendor:vulkan"

Device_Config :: struct {
	extensions: []cstring,
	features:   vk.PhysicalDeviceFeatures,
}

Swapchain_Support :: struct {
	capabilities:    vk.SurfaceCapabilitiesKHR,
	surface_formats: []vk.SurfaceFormatKHR,
	present_modes:   []vk.PresentModeKHR,
}

create_device_assets :: proc(
	ctx: ^Context,
	config: Device_Config,
	instance: vk.Instance,
	surface: vk.SurfaceKHR,
) {
	choose_physical_device_and_queues(ctx, config, instance, surface)
	choose_logical_device(ctx, config)
}

@(private = "file")
choose_physical_device_and_queues :: proc(
	ctx: ^Context,
	config: Device_Config,
	instance: vk.Instance,
	surface: vk.SurfaceKHR,
) {
	physical_device_count: u32
	vk.EnumeratePhysicalDevices(instance, &physical_device_count, nil)

	assert(physical_device_count != 0, "No physical devices were found")

	physical_devices := make([]vk.PhysicalDevice, physical_device_count)
	vk.EnumeratePhysicalDevices(instance, nil, raw_data(physical_devices))
	choosen := false

	for physical_device in physical_devices {
		found, graphics_queue, present_queue := get_queue_families(physical_device, surface)
		if !found {
			continue
		}

		complete, swapchain_support := query_swapchain_support(physical_device, surface)
		if !complete {
			continue
		}

		if !supports_extensions(physical_device, config.extensions) {
			continue
		}

		if !supports_features(physical_device, config.features) {
			continue
		}

		ctx.physical_device = physical_device
		ctx.graphics_queue.family = graphics_queue
		ctx.present_queue.family = present_queue

		break
	}
}

@(private = "file")
choose_logical_device :: proc(ctx: ^Context, config: Device_Config) {
	features := config.features

	// if the graphics_queue and present_queue are the same,
	// only the first element will be set
	// otherwise both are set
	queue_create_infos: [2]vk.DeviceQueueCreateInfo

	unique_queue_families := 1 if ctx.graphics_queue.family == ctx.present_queue.family else 2

	queue_family_indices := [2]u32{ctx.graphics_queue.family, ctx.present_queue.family}

	for i in 0 ..< unique_queue_families {
		queue_create_info := vk.DeviceQueueCreateInfo {
			sType            = .DEVICE_QUEUE_CREATE_INFO,
			queueFamilyIndex = queue_family_indices[i],
			queueCount       = 1,
		}

		queue_create_infos[i] = queue_create_info
	}

	device_info := vk.DeviceCreateInfo {
		sType                = .DEVICE_CREATE_INFO,
		queueCreateInfoCount = u32(unique_queue_families),
		pQueueCreateInfos    = raw_data(queue_create_infos[:]),
		pEnabledFeatures     = &features,
	}

	result := vk.CreateDevice(ctx.physical_device, &device_info, nil, &ctx.device)
	if result != .SUCCESS {
		fmt.panicf("Failed to create the logical device (result: %v)", result)
	}
}

@(private = "file")
get_queue_families :: proc(device: vk.PhysicalDevice, surface: vk.SurfaceKHR) -> (bool, u32, u32) {
	graphics_queue, present_queue: u32 = ~u32(0), ~u32(0)

	queue_family_count: u32
	vk.GetPhysicalDeviceQueueFamilyProperties(device, &queue_family_count, nil)

	assert(queue_family_count != 0, "No queue families were found")

	queue_families := make([]vk.QueueFamilyProperties, queue_family_count)
	vk.GetPhysicalDeviceQueueFamilyProperties(device, nil, raw_data(queue_families))

	for family, i in queue_families {
		if family.queueCount <= 0 {
			continue
		}

		if .GRAPHICS in family.queueFlags {
			graphics_queue = u32(i)
		}

		present_supported: b32
		vk.GetPhysicalDeviceSurfaceSupportKHR(device, u32(i), surface, &present_supported)

		if present_supported {
			present_queue = u32(i)
		}

		if graphics_queue != ~u32(0) && present_queue != ~u32(0) {
			return true, graphics_queue, present_queue
		}
	}

	return false, 0, 0
}

@(private = "file")
query_swapchain_support :: proc(
	device: vk.PhysicalDevice,
	surface: vk.SurfaceKHR,
) -> (
	bool,
	Swapchain_Support,
) {
	support: Swapchain_Support

	vk.GetPhysicalDeviceSurfaceCapabilitiesKHR(device, surface, &support.capabilities)
	surface_format_count: u32
	vk.GetPhysicalDeviceSurfaceFormatsKHR(device, surface, &surface_format_count, nil)

	if surface_format_count == 0 {
		return false, support
	}

	support.surface_formats = make([]vk.SurfaceFormatKHR, surface_format_count)
	vk.GetPhysicalDeviceSurfaceFormatsKHR(device, surface, nil, raw_data(support.surface_formats))

	present_modes_count: u32
	vk.GetPhysicalDeviceSurfacePresentModesKHR(device, surface, &present_modes_count, nil)

	if present_modes_count == 0 {
		return false, support
	}

	support.present_modes = make([]vk.PresentModeKHR, present_modes_count)
	vk.GetPhysicalDeviceSurfacePresentModesKHR(
		device,
		surface,
		nil,
		raw_data(support.present_modes),
	)

	return true, support
}

@(private = "file")
supports_extensions :: proc(device: vk.PhysicalDevice, required_extensions: []cstring) -> bool {
	extension_count: u32
	vk.EnumerateDeviceExtensionProperties(device, nil, &extension_count, nil)

	assert(extension_count == 0, "No device extension are available")

	available_extensions := make([]vk.ExtensionProperties, extension_count)
	vk.EnumerateDeviceExtensionProperties(device, nil, nil, raw_data(available_extensions))

	found: u32
	for extension in available_extensions {
		extension_name := extension.extensionName

		if slice.contains(required_extensions[:], cstring(raw_data(extension_name[:]))) {
			found += 1
		}
	}

	return extension_count == found
}

@(private = "file")
supports_features :: proc(
	device: vk.PhysicalDevice,
	required_features: vk.PhysicalDeviceFeatures,
) -> bool {
	required_features := required_features

	features: vk.PhysicalDeviceFeatures
	vk.GetPhysicalDeviceFeatures(device, &features)

	// there are exactly 55 features in the vk.PhysicalDeviceFeatures struct
	// all of them are b32's
	// yes this is scuffed
	for i in 0 ..< 55 {
		if mem.ptr_offset(&features, i) < mem.ptr_offset(&required_features, i) {
			return false
		}
	}

	return true
}
