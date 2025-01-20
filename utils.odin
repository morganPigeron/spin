package main

import "core:math"

nearest_grid_pos :: proc(pos: [2]f32, spacing: f32) -> (result: [2]f32) {
	result.x = math.floor(pos.x / spacing) * spacing
	result.y = math.floor(pos.y / spacing) * spacing
	return
}

polar_to_cartesian :: proc(radius: f32, angle_rad: f32) -> [2]f32 {
	return {radius * math.cos(angle_rad), radius * math.sin(angle_rad)}
}
