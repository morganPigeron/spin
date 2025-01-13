package main

import rl "vendor:raylib"

import "core:math"

Image :: struct {
	pos:     rl.Vector2,
	asset:   Assets,
	texture: rl.Texture,
}

is_overlapping_image :: proc(point: [2]f32, image: Image) -> bool {
	return rl.CheckCollisionPointRec(
		point.xy,
		{image.pos.x, image.pos.y, f32(image.texture.width), f32(image.texture.height)},
	)
}

create_image :: proc(ctx: GameCtx, pos: rl.Vector2, asset: Assets) -> (image: Image) {
	image.asset = asset
	image.pos = pos
	image.texture = ctx.assets[asset]
	return
}

render_image :: proc(image: Image) {
	rl.DrawTextureV(image.texture, image.pos, rl.WHITE)
}
