package main

import b2 "vendor:box2d"
import rl "vendor:raylib"

import "core:log"

setup_menu_scene :: proc(game_ctx: ^GameCtx) {
    game_ctx.wheel.position = {f32(state.screen_width / 2), f32(state.screen_height / 2)}

    if !rl.IsMusicValid(game_ctx.musics[.MAIN_THEME]) {
	log.error("music is not valid")
    }

    start_wheel(&game_ctx.wheel)
}

update_menu_scene :: proc(game_ctx: ^GameCtx) {
    update_wheel(game_ctx^, &game_ctx.wheel)
    update_clock(&game_ctx.game_clock)
    rl.UpdateMusicStream(game_ctx.musics[.MAIN_THEME])
    if !rl.IsMusicStreamPlaying(game_ctx.musics[.MAIN_THEME]) {
	rl.PlayMusicStream(game_ctx.musics[.MAIN_THEME])
	rl.SetMusicVolume(game_ctx.musics[.MAIN_THEME], DEFAULT_VOLUME)
    }
}

render_menu_scene :: proc(game_ctx: ^GameCtx) {
    {
	rl.BeginMode2D(game_ctx.camera)
	defer rl.EndMode2D()

	render_wheel(game_ctx^, game_ctx.wheel)
    }

    
    {
	text: cstring = "Kill the boss before 17:30h!"
	size := rl.MeasureText(text, 40)
	left := f32(rl.GetScreenWidth())/2.0 - f32(size)/2.0
	y :i32 = rl.GetScreenHeight()/2 + 20
	rl.DrawText(text, i32(left), y, 40, rl.BLACK)
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

    if (game_ctx.is_editor) {
	rl.DrawFPS(10, 10)
    }
}
