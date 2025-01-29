package svk

Pipeline_Config :: struct {}

Pipeline_Record :: struct {
	descriptor_sets: []^DescriptorSet,
	push_constants:  []^PushConstant,
}

Pipeline :: struct {}

create_pipeline :: proc(config: Pipeline_Config) {

}
