package main

import rl "vendor:raylib"

import "core:math"

enter_editor :: proc(game_ctx: ^GameCtx) {

}

update_editor :: proc(game_ctx: ^GameCtx) {

	if rl.IsKeyPressed(game_ctx.key_inputs[.TOGGLE_EDITOR]) {
		game_ctx.is_editor = !game_ctx.is_editor
	}

	MARGIN :: 75

	if game_ctx.is_editor {
		mouse := rl.GetMousePosition()
		if mouse.x < MARGIN {
			game_ctx.camera.target.x -= 10
		} else if mouse.x > f32(rl.GetScreenWidth() - MARGIN) {
			game_ctx.camera.target.x += 10
		}

		if mouse.y < MARGIN {
			game_ctx.camera.target.y -= 10
		} else if mouse.y > f32(rl.GetScreenHeight() - MARGIN) {
			game_ctx.camera.target.y += 10
		}

		scroll := rl.GetMouseWheelMove()
		if scroll != 0 {
			game_ctx.camera.zoom += scroll * rl.GetFrameTime()
		}

	} else {

	}
}

render_editor :: proc(game_ctx: ^GameCtx) {
	if game_ctx.is_editor {

		screen: rl.Vector2 = {f32(rl.GetScreenWidth()), f32(rl.GetScreenHeight())}
		cam: rl.Vector2 = game_ctx.camera.target
		top_left := rl.GetScreenToWorld2D({0, 0}, game_ctx.camera)
		bottom_right := rl.GetScreenToWorld2D(screen, game_ctx.camera)

		{ 	// world space
			rl.BeginMode2D(game_ctx.camera)
			defer rl.EndMode2D()

			// GRID
			a := nearest_grid_pos(top_left.xy, GRID_SPACING)
			b := nearest_grid_pos(bottom_right.xy, GRID_SPACING)
			for i := min(0, a.x); i < b.x; i += GRID_SPACING {
				start: rl.Vector2 = {i, a.y}
				end: rl.Vector2 = {i, b.y}
				rl.DrawLineEx(start, end, 2, rl.GRAY)
			}
			for i := min(0, a.y); i < b.y; i += GRID_SPACING {
				start: rl.Vector2 = {a.x, i}
				end: rl.Vector2 = {b.x, i}
				rl.DrawLineEx(start, end, 2, rl.GRAY)
			}

			// PLAYERVIEW
			rl.DrawLineEx({0, 0} + cam, {INITIAL_SCREEN_WIDTH, 0} + cam, 4, rl.PURPLE)
			rl.DrawLineEx(
				{INITIAL_SCREEN_WIDTH, 0} + cam,
				{INITIAL_SCREEN_WIDTH, INITIAL_SCREEN_HEIGHT} + cam,
				4,
				rl.PURPLE,
			)
			rl.DrawLineEx(
				{INITIAL_SCREEN_WIDTH, INITIAL_SCREEN_HEIGHT} + cam,
				{0, INITIAL_SCREEN_HEIGHT} + cam,
				4,
				rl.PURPLE,
			)
			rl.DrawLineEx({0, INITIAL_SCREEN_HEIGHT} + cam, {0, 0} + cam, 4, rl.PURPLE)

			mouse := rl.GetScreenToWorld2D(rl.GetMousePosition(), game_ctx.camera)
			if game_ctx.editor_mode == .PlaceGround {
				pos: rl.Vector2 = nearest_grid_pos(mouse.xy, GRID_SPACING)
				rl.DrawRectangleV(pos, {UNIT, UNIT}, rl.BROWN)
			}
		}

		{ 	//screen space
			BUTTON_SIZE: rl.Vector2 : {150, 30}
			if rl.GuiButton(
				{screen.x - BUTTON_SIZE.x - 150, 150, BUTTON_SIZE.x, BUTTON_SIZE.y},
				"place ground",
			) {
				game_ctx.editor_mode = .PlaceGround
			}
		}
	}
}
