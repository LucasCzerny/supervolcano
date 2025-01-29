package svk

import "core:math"

import "vendor:glfw"
import vk "vendor:vulkan"

Swapchain_Config :: struct {}

Swapchain :: struct {
	handle:         vk.SwapchainKHR,
	format:         vk.SurfaceFormatKHR,
	present_mode:   vk.PresentModeKHR,
	extent:         vk.Extent2D,
	// don't modify
	_old_swapchain: vk.SwapchainKHR,
}

create_swapchain :: proc(
	config: Swapchain_Config,
	support: Swapchain_Support,
	window: Window,
) -> Swapchain {
	swapchain: Swapchain

	swapchain.format = choose_surface_format(support.surface_formats)
	swapchain.present_mode = choose_present_mode(support.present_modes)
	swapchain.extent = choose_extent(support.capabilities, window.handle)

	return swapchain
}

recreate_swapchain :: proc() {

}

@(private = "file")
choose_surface_format :: proc(formats: []vk.SurfaceFormatKHR) -> vk.SurfaceFormatKHR {
	for format in formats {
		if format.format == .B8G8R8_SRGB && format.colorSpace == .COLORSPACE_SRGB_NONLINEAR {
			return format
		}
	}

	panic("Could not find a surface format that supports SRGB")
}

@(private = "file")
choose_present_mode :: proc(modes: []vk.PresentModeKHR) -> vk.PresentModeKHR {
	for mode in modes {
		if mode == .MAILBOX {
			return mode
		}
	}

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
