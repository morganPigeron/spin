package main

import rl "vendor:raylib"

GameCtx :: struct {
	camera:  rl.Camera2D,
	player:  Player,
	wheel:   Wheel,
	ground:  Ground,
	enemies: [dynamic]Enemy,
}

new_game_ctx :: proc() -> (ctx: GameCtx) {
	ctx.enemies = make([dynamic]Enemy, 0, 100)
	return
}

delete_game_ctx :: proc(ctx: GameCtx) {
	for e in ctx.enemies {
		cleanup_enemy(e)
	}
	delete(ctx.enemies)
}
