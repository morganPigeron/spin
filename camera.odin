package main

import b2 "vendor:box2d"
import rl "vendor:raylib"

import "core:math"

update_camera :: proc(ctx: ^GameCtx) {
	@(static) last_position: rl.Vector2
	pos := b2.Body_GetPosition(ctx.player.body_id)
	delta_pos := pos - last_position
	last_position += delta_pos * 0.05
	ctx.camera.target = last_position
	ctx.camera.offset = {f32(rl.GetScreenWidth()), f32(rl.GetScreenHeight())} / 2
}
