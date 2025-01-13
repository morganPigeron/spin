package main

import b2 "vendor:box2d"
import rl "vendor:raylib"

setup_test_scene :: proc(game_ctx: ^GameCtx) {
	game_ctx.wheel.position = {175 + 20, 175 + 20}
}

update_test_scene :: proc(game_ctx: ^GameCtx) {
	contact_events: b2.ContactEvents
	{
		dt := rl.GetFrameTime()
		b2.World_Step(game_ctx.world_id, dt, 4)

		contact_events = b2.World_GetContactEvents(game_ctx.world_id)
	}

	update_player(&game_ctx.player, contact_events)
	for &enemy in game_ctx.enemies {
		update_enemy(&enemy, contact_events)
		enemy.behavior(&enemy, game_ctx^)
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
}

render_test_scene :: proc(game_ctx: ^GameCtx) {

	{
		rl.BeginMode2D(game_ctx.camera)
		defer rl.EndMode2D()

		render_wheel(game_ctx.wheel)

		for ground in game_ctx.grounds {
			render_ground(ground)
		}
		for image in game_ctx.images {
			render_image(image)
		}
		for &enemy in game_ctx.enemies {
			render_enemy(enemy)
		}
		render_player(game_ctx.player)
		for bullet in game_ctx.bullets {
			render_bullet(bullet)
		}
	}

	rl.DrawFPS(10, 10)
}
