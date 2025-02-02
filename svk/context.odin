package svk

import "vendor:glfw"
import vk "vendor:vulkan"

Context :: struct {
	instance:          vk.Instance,
	window:            Window,
	//
	device:            vk.Device,
	physical_device:   vk.PhysicalDevice,
	swapchain_support: Swapchain_Support,
	//
	graphics_queue:    Queue,
	present_queue:     Queue,
	//
	swapchain:         Swapchain,
	//
	command_pool:      vk.CommandPool,
	command_buffers:   []vk.CommandBuffer,
	//
	descriptor_pool:   vk.DescriptorPool,
}

create_context :: proc(
	instance_config: Instance_Config,
	window_config: Window_Config,
	device_config: Device_Config,
	swapchain_config: Swapchain_Config,
	command_config: Commands_Config,
	descriptor_config: Descriptor_Config,
) -> Context {
	ctx: Context

	if !glfw.Init() {
		panic("Failed to initialize glfw")
	}
	init_vulkan()

	create_instance(&ctx.instance, instance_config)

	create_window(&ctx.window, window_config, ctx.instance)

	create_devices_and_queues(&ctx, device_config, ctx.instance, ctx.window.surface)

	create_swapchain(&ctx, swapchain_config)

	create_command_pool(&ctx, command_config)
	create_command_buffers(&ctx, command_config)

	create_descriptor_pool(&ctx, descriptor_config)

	return ctx
}

destroy_context :: proc(ctx: ^Context) {
	vk.DestroyInstance(ctx.instance, nil)

	glfw.Terminate()
	vk.DestroySurfaceKHR(ctx.instance, ctx.window.surface, nil)
	glfw.DestroyWindow(ctx.window.handle)

	vk.DeviceWaitIdle(ctx.device)
	vk.DestroySwapchainKHR(ctx.device, ctx.swapchain.handle, nil)

	vk.DestroyCommandPool(ctx.device, ctx.command_pool, nil)

	vk.DestroyDescriptorPool(ctx.device, ctx.descriptor_pool, nil)
}

@(private)
init_vulkan :: proc() {
	instance: vk.Instance
	context.user_ptr = &instance

	get_proc_address :: proc(p: rawptr, name: cstring) {
		(cast(^rawptr)p)^ = glfw.GetInstanceProcAddress((^vk.Instance)(context.user_ptr)^, name)
	}

	vk.load_proc_addresses(get_proc_address)
}

