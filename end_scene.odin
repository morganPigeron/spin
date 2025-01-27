package main

import "core:math"

import b2 "vendor:box2d"
import rl "vendor:raylib"

setup_end_scene :: proc(game_ctx: ^GameCtx) {
    game_ctx.wheel.position = {f32(state.screen_width / 2), f32(state.screen_height / 2)}
    //start_wheel(&game_ctx.wheel)
}

update_end_scene :: proc(game_ctx: ^GameCtx) {
    update_wheel(game_ctx^, &game_ctx.wheel)
    //update_clock(&game_ctx.game_clock)
    sound :: Sounds.GOOD_SPIN_2
    rl.UpdateMusicStream(game_ctx.musics[sound])
    if !rl.IsMusicStreamPlaying(game_ctx.musics[sound]) {
	rl.PlayMusicStream(game_ctx.musics[sound])
	rl.SetMusicVolume(game_ctx.musics[sound], 0.1)
    }
}

render_end_scene :: proc(game_ctx: ^GameCtx) {
    {
	rl.BeginMode2D(game_ctx.camera)
	defer rl.EndMode2D()

	render_wheel(game_ctx^, game_ctx.wheel)
    }

    {
	screen: rl.Vector2 = {f32(state.screen_width), f32(state.screen_height)}

	button_size: rl.Vector2 = {200, 30}
	if rl.GuiButton(
	    {
		screen.x / 2 - button_size.x / 2,
		screen.y / 2 - button_size.y / 2,
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
