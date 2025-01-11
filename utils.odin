package main

import "core:math"

nearest_grid_pos :: proc(pos: [2]f32, spacing: f32) -> (result: [2]f32) {
	result.x = math.round(pos.x / spacing) * spacing
	result.y = math.round(pos.y / spacing) * spacing
	return
}
