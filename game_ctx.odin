package main

import b2 "vendor:box2d"
import rl "vendor:raylib"

GameCtx :: struct {
	world_id: b2.WorldId,
	camera:   rl.Camera2D,
	player:   Player,
	wheel:    Wheel,
	ground:   Ground,
	enemies:  [dynamic]Enemy,
	bullets:  [dynamic]Bullet,
}

spawn_player_bullet :: proc(ctx: ^GameCtx, start_pos: rl.Vector2, direction: rl.Vector2) {
	create_bullet_from_player(ctx.world_id)
}

new_game_ctx :: proc() -> (ctx: GameCtx) {
	ctx.enemies = make([dynamic]Enemy, 0, 100)
	ctx.bullets = make([dynamic]Bullet, 0, 100)
	return
}

delete_game_ctx :: proc(ctx: GameCtx) {
	for e in ctx.enemies {
		cleanup_enemy(e)
	}
	delete(ctx.enemies)
	delete(ctx.bullets)
}
