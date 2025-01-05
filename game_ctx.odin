package main

GameCtx :: struct {
	player:  Player,
	wheel:   Wheel,
	enemies: [dynamic]Enemy,
}

new_game_ctx :: proc() -> (ctx: GameCtx) {
	ctx.enemies = make([dynamic]Enemy, 0, 100)
	return
}

delete_game_ctx :: proc(ctx: GameCtx) {
	delete(ctx.enemies)
}
