package main

import rl "vendor:raylib"

Image :: struct {
	pos:     rl.Vector2,
	asset:   Assets,
	texture: rl.Texture,
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
