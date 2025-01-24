package main

import "core:fmt"

import "vendor:glfw"
import vk "vendor:vulkan"

import "svk"

main :: proc() {
	instance_config := svk.Instance_Config {
		name                     = "Test Application",
		major                    = 0,
		minor                    = 1,
		extensions               = []cstring{"VK_EXT_DEBUG_UTILS"},
		enable_validation_layers = true,
	}

	window_config := svk.Window_Config {
		window_title   = "Test Window",
		initial_width  = 1280,
		initial_height = 720,
		resizable      = true,
		fullscreen     = false,
	}

	ctx := svk.create_context(instance_config, window_config)
	defer svk.destroy_context(&ctx)
}

