package main

import b2 "vendor:box2d"
import rl "vendor:raylib"

InputList :: enum {
	UP,
	DOWN,
	LEFT,
	RIGHT,
	JUMP,
	SHOOT,
}

GameCtx :: struct {
	world_id:   b2.WorldId,
	camera:     rl.Camera2D,
	player:     Player,
	wheel:      Wheel,
	ground:     Ground,
	enemies:    [dynamic]Enemy,
	bullets:    [dynamic]Bullet,
	key_inputs: [InputList]rl.KeyboardKey,
}

spawn_player_bullet :: proc(ctx: ^GameCtx, start_pos: rl.Vector2, direction: rl.Vector2) {
	append(&ctx.bullets, create_bullet_from_player(ctx.world_id))
	bullet := &ctx.bullets[len(ctx.bullets) - 1]
	bullet.direction = direction
	b2.Shape_SetUserData(bullet.shape_id, &bullet.shape_id)
	b2.Body_SetTransform(bullet.body_id, start_pos, {0, 0})
	b2.Body_ApplyLinearImpulseToCenter(
		bullet.body_id,
		bullet.speed * UNIT * bullet.direction,
		true,
	)
}

new_game_ctx :: proc() -> (ctx: GameCtx) {
	ctx.enemies = make([dynamic]Enemy, 0, 100)
	ctx.bullets = make([dynamic]Bullet, 0, 100)
	ctx.key_inputs = {
		.UP    = .W,
		.DOWN  = .S,
		.LEFT  = .A,
		.RIGHT = .D,
		.JUMP  = .SPACE,
		.SHOOT = .LEFT_CONTROL,
	}
	return
}

delete_game_ctx :: proc(ctx: GameCtx) {

	// TODO cleanup box2D physic
	//b2.DestroyWorld(ctx.world_id)
	for e in ctx.enemies {
		cleanup_enemy(e)
	}
	delete(ctx.enemies)
	delete(ctx.bullets)
}
