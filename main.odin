package main

import vk "vendor:vulkan"

import "svk"

main :: proc() {
	instance_config :: svk.Instance_Config {
		name                     = "Test Application",
		major                    = 0,
		minor                    = 1,
		extensions               = []cstring{"VK_EXT_debug_utils"},
		enable_validation_layers = true,
	}

	window_config :: svk.Window_Config {
		window_title   = "Test Window",
		initial_width  = 1280,
		initial_height = 720,
		resizable      = true,
		fullscreen     = false,
	}

	device_config :: svk.Device_Config {
		extensions = []cstring{"VK_KHR_swapchain", "VK_EXT_descriptor_indexing"},
		features = vk.PhysicalDeviceFeatures{samplerAnisotropy = true},
	}

	swapchain_config :: svk.Swapchain_Config {
		format       = .B8G8R8A8_SRGB,
		color_space  = .COLORSPACE_SRGB_NONLINEAR,
		present_mode = .MAILBOX,
	}

	commands_config :: svk.Commands_Config {
		nr_command_buffers = 2,
	}

	descriptor_config :: svk.Descriptor_Config {
		max_sets    = 1,
		nr_samplers = 1,
	}

	ctx := svk.create_context(
		instance_config,
		window_config,
		device_config,
		swapchain_config,
		commands_config,
		descriptor_config,
	)
	defer svk.destroy_context(&ctx)
}

