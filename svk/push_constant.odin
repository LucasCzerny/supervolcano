package svk

import vk "vendor:vulkan"

Push_Constant :: struct {
	stage_flags: vk.ShaderStageFlags,
	offset:      u32,
	size:        u32,
	data:        rawptr,
}

