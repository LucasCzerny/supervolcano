package svk

import vk "vendor:vulkan"

Pipeline_Config :: struct {
	pipeline_layout_info:                     vk.PipelineLayoutCreateInfo,
	render_pass_info:                         vk.RenderPassCreateInfo,
	vertex_shader_path, fragment_shader_path: string,
	// all of these have a default value (see create_pipeline)
	viewport_info:                            Maybe(vk.PipelineViewportStateCreateInfo),
	input_assembly_info:                      Maybe(vk.PipelineInputAssemblyStateCreateInfo),
	rasterization_info:                       Maybe(vk.PipelineRasterizationStateCreateInfo),
	multisample_info:                         Maybe(vk.PipelineMultisampleStateCreateInfo),
	color_blend_attachment:                   Maybe(vk.PipelineColorBlendAttachmentState),
	color_blend_info:                         Maybe(vk.PipelineColorBlendStateCreateInfo),
	depth_stencil_info:                       Maybe(vk.PipelineDepthStencilStateCreateInfo),
	dynamic_state_enables:                    Maybe([]vk.DynamicState),
	dynamic_state_info:                       Maybe(vk.PipelineDynamicStateCreateInfo),
	subpass:                                  Maybe(u32),
	binding_descriptions:                     Maybe([]vk.VertexInputBindingDescription),
	attribute_descriptions:                   Maybe([]vk.VertexInputAttributeDescription),
}

Pipeline_Record :: struct {
	clear_color:     [4]f32,
	descriptor_sets: []Descriptor_Set,
	push_constants:  []Push_Constant,
}

Pipeline :: struct {
	handle:       vk.Pipeline,
	layout:       vk.PipelineLayout,
	render_pass:  vk.RenderPass,
	framebuffers: []vk.Framebuffer,
}

create_pipeline :: proc(config: Pipeline_Config) -> (pipeline: Pipeline) {
	return
}

