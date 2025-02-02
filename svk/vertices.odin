package svk

import vk "vendor:vulkan"

Pos_Tex_2D :: struct {
	position:   [2]f32,
	tex_coords: [2]f32,
}

binding_descriptions_pos_tex_2d :: proc() -> (descriptions: []vk.VertexInputBindingDescription) {
	descriptions[0] = {
		binding   = 0,
		stride    = size_of([2]f32),
		inputRate = .VERTEX,
	}

	descriptions[1] = {
		binding   = 1,
		stride    = size_of([2]f32),
		inputRate = .VERTEX,
	}

	return
}

attribute_descriptions_pos_tex_2d :: proc(
) -> (
	descriptions: []vk.VertexInputAttributeDescription,
) {
	descriptions[0] = {
		binding  = 0,
		location = 0,
		format   = .R32G32_SFLOAT,
		offset   = 0,
	}

	descriptions[1] = {
		binding  = 1,
		location = 1,
		format   = .R32G32_SFLOAT,
		offset   = 0,
	}

	return
}

