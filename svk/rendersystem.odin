package svk

Rendersystem_Config :: struct {}

Rendersystem :: struct {
	pipelines: []Pipeline,
}

create_rendersystem :: proc(config: Rendersystem_Config) {

}

render :: proc(rendersystem: RenderSystem) {
	for pipeline in rendersystem.pipelines {
		// vk.BeginCommandBuffer

		r := pipeline.record_funcion

		for descriptor, slot in r.descriptor_sets {
			descriptor.bind(command_buffer, slot)
		}

		r.push_constant.bind(command_buffer)
	}
}
