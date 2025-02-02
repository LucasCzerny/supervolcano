package svk

import "core:fmt"

import vk "vendor:vulkan"

Descriptor_Set :: struct {
	set:    vk.DescriptorSet,
	layout: vk.DescriptorSetLayout,
}

create_descriptor_set :: proc(
	ctx: ^Context,
	layout_info: vk.DescriptorSetLayoutCreateInfo,
) -> Descriptor_Set {
	descriptor_set: Descriptor_Set

	layout_info := layout_info

	result := vk.CreateDescriptorSetLayout(ctx.device, &layout_info, nil, &descriptor_set.layout)
	if result != .SUCCESS {
		fmt.panicf("Failed to create the descriptor set layout (result: %v)", result)
	}

	alloc_info := vk.DescriptorSetAllocateInfo {
		sType              = .DESCRIPTOR_SET_ALLOCATE_INFO,
		descriptorPool     = ctx.descriptor_pool,
		descriptorSetCount = 1,
		pSetLayouts        = &descriptor_set.layout,
	}

	result = vk.AllocateDescriptorSets(ctx.device, &alloc_info, &descriptor_set.set)
	if result != .SUCCESS {
		fmt.panicf("Failed to allocate the descriptor set (result: %v)", result)
	}

	return descriptor_set
}

update_descriptor_set :: proc {
	update_descriptor_set_buffer,
	update_descriptor_set_image,
}

update_descriptor_set_buffer :: proc(
	ctx: ^Context,
	descriptor_set: Descriptor_Set,
	buffer_info: vk.DescriptorBufferInfo,
	binding: u32,
	descriptor_type: vk.DescriptorType = .UNIFORM_BUFFER,
) {
	buffer_info := buffer_info

	write_descriptor := vk.WriteDescriptorSet {
		dstSet          = descriptor_set.set,
		dstBinding      = binding,
		descriptorCount = 1,
		descriptorType  = descriptor_type,
		pBufferInfo     = &buffer_info,
	}

	vk.UpdateDescriptorSets(ctx.device, 1, &write_descriptor, 0, nil)
}

update_descriptor_set_image :: proc(
	ctx: ^Context,
	descriptor_set: Descriptor_Set,
	image_info: vk.DescriptorImageInfo,
	binding: u32,
	descriptor_type: vk.DescriptorType = .COMBINED_IMAGE_SAMPLER,
) {
	image_info := image_info

	write_descriptor := vk.WriteDescriptorSet {
		dstSet          = descriptor_set.set,
		dstBinding      = binding,
		descriptorCount = 1,
		descriptorType  = descriptor_type,
		pImageInfo      = &image_info,
	}

	vk.UpdateDescriptorSets(ctx.device, 1, &write_descriptor, 0, nil)
}

