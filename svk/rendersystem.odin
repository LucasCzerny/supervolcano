package svk

import "core:fmt"

import vk "vendor:vulkan"

Rendersystem :: struct {
	pipelines:                     []Pipeline,
	max_frames_in_flight:          u32,
	image_available_semaphores:    []vk.Semaphore,
	rendering_finished_semaphores: []vk.Semaphore,
	in_flight_fences:              []vk.Fence,
}

create_rendersystem :: proc(
	ctx: ^Context,
	pipelines: []Pipeline,
	max_frames_in_flight: u32,
) -> (
	rendersystem: Rendersystem,
) {
	rendersystem.pipelines = pipelines
	rendersystem.max_frames_in_flight = max_frames_in_flight

	rendersystem.image_available_semaphores = make([]vk.Semaphore, max_frames_in_flight)
	rendersystem.rendering_finished_semaphores = make([]vk.Semaphore, max_frames_in_flight)
	rendersystem.in_flight_fences = make([]vk.Fence, max_frames_in_flight)

	semaphore_info := vk.SemaphoreCreateInfo {
		sType = .SEMAPHORE_CREATE_INFO,
	}

	fence_info := vk.FenceCreateInfo {
		sType = .FENCE_CREATE_INFO,
		flags = {.SIGNALED},
	}

	for i in 0 ..< max_frames_in_flight {
		result := vk.CreateSemaphore(
			ctx.device,
			&semaphore_info,
			nil,
			&rendersystem.image_available_semaphores[i],
		)
		if result != .SUCCESS {
			fmt.panicf(
				"Failed to create the %d. image available sempahore (result: %v)",
				i,
				result,
			)
		}

		result = vk.CreateSemaphore(
			ctx.device,
			&semaphore_info,
			nil,
			&rendersystem.rendering_finished_semaphores[i],
		)
		if result != .SUCCESS {
			fmt.panicf(
				"Failed to create the %d. rendering finished sempahore (result: %v)",
				i,
				result,
			)
		}

		result = vk.CreateFence(ctx.device, &fence_info, nil, &rendersystem.in_flight_fences[i])
		if result != .SUCCESS {
			fmt.panicf("Failed to create the %d. in flight fence (result: %v)", i, result)
		}
	}

	return
}

destroy_rendersystem :: proc(ctx: ^Context, rendersystem: Rendersystem) {
	for pipeline in rendersystem.pipelines {
		vk.DestroyPipeline(ctx.device, pipeline.handle, nil)
		vk.DestroyPipelineLayout(ctx.device, pipeline.layout, nil)
		vk.DestroyRenderPass(ctx.device, pipeline.render_pass, nil)
	}

	for i in 0 ..< rendersystem.max_frames_in_flight {
		vk.DestroySemaphore(ctx.device, rendersystem.image_available_semaphores[i], nil)
		vk.DestroySemaphore(ctx.device, rendersystem.rendering_finished_semaphores[i], nil)
		vk.DestroyFence(ctx.device, rendersystem.in_flight_fences[i], nil)
	}
}

start_recording :: proc(ctx: ^Context, rendersystem: Rendersystem) {
	for pipeline in rendersystem.pipelines {
		// vk.BeginCommandBuffer

		r := pipeline.record_data

		for descriptor, slot in r.descriptor_sets {
			// bind_descriptor_set(ctx, descriptor, slot)
		}

		// r.push_constant.bind(command_buffer)
	}
}

stop_recording :: proc(ctx: ^Context, rendersystem: Rendersystem) {

}

