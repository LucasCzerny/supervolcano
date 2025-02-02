package svk

import "core:fmt"

import "vendor:glfw"
import vk "vendor:vulkan"

Instance_Config :: struct {
	name:                     cstring,
	major:                    u32,
	minor:                    u32,
	patch:                    u32,
	extensions:               []cstring,
	enable_validation_layers: bool,
}

@(private)
create_instance :: proc(instance: ^vk.Instance, config: Instance_Config) {
	app_info := vk.ApplicationInfo {
		sType              = .APPLICATION_INFO,
		pApplicationName   = config.name,
		applicationVersion = vk.MAKE_VERSION(config.major, config.minor, config.patch),
		pEngineName        = "svk",
		engineVersion      = vk.MAKE_VERSION(0, 1, 0),
		apiVersion         = vk.API_VERSION_1_0,
	}

	glfw_extensions: []cstring = glfw.GetRequiredInstanceExtensions()
	assert(len(glfw_extensions) != 0, "No GLFW extensions were found")

	extensions: [dynamic]cstring
	reserve(&extensions, len(config.extensions) + len(glfw_extensions))

	append(&extensions, ..config.extensions)
	append(&extensions, ..glfw_extensions)

	create_info := vk.InstanceCreateInfo {
		sType                   = .INSTANCE_CREATE_INFO,
		pApplicationInfo        = &app_info,
		enabledExtensionCount   = cast(u32)len(extensions),
		ppEnabledExtensionNames = raw_data(extensions),
	}

	validation_layer: cstring = "VK_LAYER_KHRONOS_validation"

	if config.enable_validation_layers {
		create_info.enabledLayerCount = 1
		create_info.ppEnabledLayerNames = &validation_layer
	}

	result := vk.CreateInstance(&create_info, nil, instance)
	if result != .SUCCESS {
		fmt.panicf("Failed to create the instance (result: %v)", result)
	}
}

