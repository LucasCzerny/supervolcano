package svk

import "core:fmt"

import vk "vendor:vulkan"

Commands_Config :: struct {
	nr_command_buffers: u32,
}

create_command_pool :: proc(ctx: ^Context, config: Commands_Config) {
	pool_info := vk.CommandPoolCreateInfo {
		sType            = .COMMAND_POOL_CREATE_INFO,
		queueFamilyIndex = ctx.graphics_queue.family,
	}

	result := vk.CreateCommandPool(ctx.device, &pool_info, nil, &ctx.command_pool)
	if result != .SUCCESS {
		fmt.panicf("Failed to create the command pool (result: %v)", result)
	}
}

create_command_buffers :: proc(ctx: ^Context, config: Commands_Config) {
	alloc_info := vk.CommandBufferAllocateInfo {
		commandBufferCount = config.nr_command_buffers,
	}

	ctx.command_buffers = make([]vk.CommandBuffer, config.nr_command_buffers)

	result := vk.AllocateCommandBuffers(ctx.device, nil, raw_data(ctx.command_buffers))
	if result != .SUCCESS {
		fmt.panicf("Failed to create the command buffers (result: %v)", result)
	}
}

