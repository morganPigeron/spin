package main

import b2 "vendor:box2d"
import rl "vendor:raylib"

import "core:log"

setup_menu_scene :: proc(game_ctx: ^GameCtx) {
	game_ctx.wheel.position = {f32(state.screen_width / 2), f32(state.screen_height / 2)}

	if !rl.IsMusicValid(game_ctx.main_track.music) {
		log.error("music is not valid")
	}
	if !rl.IsMusicStreamPlaying(game_ctx.main_track.music) {
		rl.PlayMusicStream(game_ctx.main_track.music)
	}

	start_wheel(&game_ctx.wheel)
}

update_menu_scene :: proc(game_ctx: ^GameCtx) {
	rl.UpdateMusicStream(game_ctx.main_track.music)
	update_wheel(&game_ctx.wheel)
}

render_menu_scene :: proc(game_ctx: ^GameCtx) {
	{
		rl.BeginMode2D(game_ctx.camera)
		defer rl.EndMode2D()

		render_wheel(game_ctx.wheel)

		screen: rl.Vector2 = {f32(state.screen_width), f32(state.screen_height)}

		button_size: rl.Vector2 = {200, 30}
		if rl.GuiButton(
			{
				screen.x / 2 - button_size.x / 2,
				screen.y / 2 - button_size.y / 2 + game_ctx.wheel.radius + 40,
				button_size.x,
				button_size.y,
			},
			"START !",
		) {
			change_scene(game_ctx, .Test)
		}
	}

	rl.DrawFPS(10, 10)
}
