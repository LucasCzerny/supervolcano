package svk

import "vendor:glfw"
import vk "vendor:vulkan"

Window_Config :: struct {
	window_title:   cstring,
	initial_width:  i32,
	initial_height: i32,
	resizable:      bool,
	fullscreen:     bool,
}

Window :: struct {
	handle:  glfw.WindowHandle,
	surface: vk.SurfaceKHR,
	width:   u32,
	height:  u32,
}

@(private)
create_window :: proc(window: ^Window, config: Window_Config, instance: vk.Instance) {
	assert(!config.fullscreen, "Fullscreen is not implemented yet")

	glfw.WindowHint(glfw.CLIENT_API, glfw.NO_API)
	glfw.WindowHint(glfw.RESIZABLE, cast(b32)config.resizable)

	window.handle = glfw.CreateWindow(
		config.initial_width,
		config.initial_height,
		config.window_title,
		nil,
		nil,
	)

	result := glfw.CreateWindowSurface(instance, window.handle, nil, &window.surface)
	if result != .SUCCESS {
		panic("Failed to create the window surface")
	}
}

