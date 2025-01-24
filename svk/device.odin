package svk

import vk "vendor:vulkan"

Device_Config :: struct {
	extensions: []cstring,
}

Device :: struct {
	logical:        vk.Device,
	physical:       vk.PhysicalDevice,
	graphics_queue: Queue,
	present_queue:  Queue,
}

Swapchain_Support :: struct {
	capabilities:    vk.SurfaceCapabilitiesKHR,
	surface_formats: []vk.SurfaceFormatKHR,
	present_modes:   []vk.PresentModeKHR,
}

create_device :: proc(
	config: Device_Config,
	instance: vk.Instance,
	surface: vk.SurfaceKHR,
) -> Device {
	device: Device

	choose_physical_device_and_queues(&device, instance, surface)

	return device
}

@(private = "file")
choose_physical_device_and_queues :: proc(
	device: ^Device,
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

		swapchain_support = query_swapchain_support()
		if !swapchain_support... {
			continue
		}

		device.physical = physical_device
		device.graphics_queue = graphics_queue
		device.present_queue = present_queue

		break
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

