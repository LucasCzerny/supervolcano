package main

import "vendor:glfw"
import vk "vendor:vulkan"

import "svk"

main :: proc() {
	instance_config :: svk.Instance_Config {
		name                     = "Test Application",
		major                    = 0,
		minor                    = 1,
		patch                    = 0,
		extensions               = {"VK_EXT_debug_utils"},
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
		extensions = {"VK_KHR_swapchain", "VK_EXT_descriptor_indexing"},
		features = {samplerAnisotropy = true},
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
		max_sets    = 0,
		nr_samplers = 0,
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

	pipeline_config := svk.Pipeline_Config {
		pipeline_layout_info = {},
		render_pass_info = {
			attachmentCount = 1,
			pAttachments = &vk.AttachmentDescription {
				format = ctx.swapchain.surface_format.format,
				samples = {._1},
				loadOp = .CLEAR,
				storeOp = .STORE,
				stencilLoadOp = {},
				stencilStoreOp = {},
				initialLayout = {},
				finalLayout = .PRESENT_SRC_KHR,
			},
		},
		vertex_shader_source = #load("shaders/vertex.spv"),
		fragment_shader_source = #load("shaders/fragment.spv"),
		binding_descriptions = svk.binding_descriptions_pos_tex_2d(),
		attribute_descriptions = svk.attribute_descriptions_pos_tex_2d(),
		subpass = 0,
	}

	pipeline := svk.create_pipeline(&ctx, pipeline_config)

	rendersystem := svk.create_rendersystem(&ctx, {pipeline}, 2)
	defer svk.destroy_rendersystem(&ctx, rendersystem)

	for !glfw.WindowShouldClose(ctx.window.handle) {
		svk.start_recording(&ctx, rendersystem)

		svk.stop_recording(&ctx)
	}
}

