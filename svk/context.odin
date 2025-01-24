package svk

import "core:fmt"

import "vendor:glfw"
import vk "vendor:vulkan"

Context :: struct {
	instance: vk.Instance,
	window:   Window,
	device:   Device,
}

create_context :: proc(
	instance_config: Instance_Config,
	window_config: Window_Config,
	device_config: Device_Config,
) -> Context {
	ctx: Context

	create_glfw_window(&ctx.window, window_config)
	init_vulkan()

	create_instance(&ctx.instance, instance_config)

	create_surface(&ctx.window, ctx.instance)

	ctx.device = create_device(device_config, ctx.instance, ctx.window.surface)

	return ctx
}

destroy_context :: proc(ctx: ^Context) {
	// instance

	vk.DestroyInstance(ctx.instance, nil)

	// window

	vk.DestroySurfaceKHR(ctx.instance, ctx.window.surface, nil)
	glfw.DestroyWindow(ctx.window.handle)
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

