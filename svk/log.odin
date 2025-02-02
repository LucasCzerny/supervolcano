package svk

import "core:fmt"

@(private)
print_warning_prefix :: proc() {
	fmt.println("\033[33m[WARNING]\033[0m")
}

