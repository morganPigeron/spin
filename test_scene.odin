package main

import b2 "vendor:box2d"
import rl "vendor:raylib"

setup_test_scene :: proc(game_ctx: ^GameCtx) {
	game_ctx.wheel.position = {175 + 20, 175 + 20}
	game_ctx.game_clock = new_game_clock()
}

update_test_scene :: proc(game_ctx: ^GameCtx) {
	contact_events: b2.ContactEvents
	{
		dt := rl.GetFrameTime()
		b2.World_Step(game_ctx.world_id, dt, 4)

		contact_events = b2.World_GetContactEvents(game_ctx.world_id)
	}

	update_player(&game_ctx.player, contact_events)

	for i := 0; i < len(game_ctx.enemies); {
		enemy := &game_ctx.enemies[i]
		update_enemy(game_ctx^, enemy, contact_events)
		enemy.behavior(enemy, game_ctx^)
		if enemy.is_dead {
			cleanup_enemy(enemy^)
			unordered_remove(&game_ctx.enemies, i)
		} else {
			i += 1
		}
	}

	for i := 0; i < len(game_ctx.bullets); {
		bullet := &game_ctx.bullets[i]
		update_bullet(bullet)
		if bullet.time_to_live_sec <= 0 {
			cleanup_bullet(bullet^)
			unordered_remove(&game_ctx.bullets, i)
		} else {
			i += 1
		}
	}

	for &sprite in game_ctx.sprites {
		update_sprite(&sprite)
	}

	{ 	//update
		if rl.IsKeyDown(game_ctx.key_inputs[.RIGHT]) {
			player_move_right(&game_ctx.player)
		} else if rl.IsKeyDown(game_ctx.key_inputs[.LEFT]) {
			player_move_left(&game_ctx.player)
		}
		if rl.IsKeyDown(game_ctx.key_inputs[.JUMP]) {
			player_jump(&game_ctx.player)
		}
		if rl.IsKeyDown(game_ctx.key_inputs[.SHOOT]) {
			player_shoot(game_ctx)
		}
	}

	update_wheel(&game_ctx.wheel)
	update_clock(&game_ctx.game_clock)
	update_camera(game_ctx)
}

render_test_scene :: proc(game_ctx: ^GameCtx) {

	{
		rl.BeginMode2D(game_ctx.camera)
		defer rl.EndMode2D()

		render_wheel(game_ctx^, game_ctx.wheel)

		for ground in game_ctx.grounds {
			render_ground(ground)
		}
		for image in game_ctx.images {
			render_image(image)
		}
		for &sprite in game_ctx.sprites {
			render_sprite(&sprite, sprite.position.xy)
		}
		for &enemy in game_ctx.enemies {
			render_enemy(enemy)
		}
		render_player(game_ctx.player)
		for &bullet in game_ctx.bullets {
			render_bullet(&bullet)
		}
	}

	rl.DrawFPS(10, 10)
}
