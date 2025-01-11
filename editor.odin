package main

import b2 "vendor:box2d"
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
		mouse := rl.GetScreenToWorld2D(rl.GetMousePosition(), game_ctx.camera)
		{ 	// world space
			rl.BeginMode2D(game_ctx.camera)
			defer rl.EndMode2D()

			// GRID
			a := nearest_grid_pos(top_left.xy, grid_spacing)
			b := nearest_grid_pos(bottom_right.xy, grid_spacing)
			for i := min(0, a.x); i < b.x; i += grid_spacing {
				start: rl.Vector2 = {i, a.y}
				end: rl.Vector2 = {i, b.y}
				rl.DrawLineEx(start, end, 1, rl.GRAY)
			}
			for i := min(0, a.y); i < b.y; i += grid_spacing {
				start: rl.Vector2 = {a.x, i}
				end: rl.Vector2 = {b.x, i}
				rl.DrawLineEx(start, end, 1, rl.GRAY)
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

			pos: rl.Vector2 = nearest_grid_pos(mouse.xy, grid_spacing)
			switch game_ctx.editor_mode {
			case .PlaceImage:
				rl.DrawTextureV(game_ctx.assets[.PLANT], pos, rl.WHITE)
			case .PlaceGround:
				rl.DrawRectangleV(pos, {UNIT, UNIT}, rl.BROWN)
			case .None:
			}
		}

		{ 	//screen space
			BUTTON_SIZE: rl.Vector2 : {150, 30}
			PADDING :: 30
			if game_ctx.editor_mode == .None {
				if rl.GuiButton(
					{screen.x - BUTTON_SIZE.x - 150, 150, BUTTON_SIZE.x, BUTTON_SIZE.y},
					"place ground",
				) {
					game_ctx.editor_mode = .PlaceGround
					grid_spacing = UNIT
				}

				if rl.GuiButton(
					{
						screen.x - BUTTON_SIZE.x - 150,
						150 + BUTTON_SIZE.y + PADDING,
						BUTTON_SIZE.x,
						BUTTON_SIZE.y,
					},
					"place image",
				) {
					game_ctx.editor_mode = .PlaceImage
					game_ctx.selected_asset = .PLANT
					grid_spacing = 8
				}
			} else if rl.IsMouseButtonPressed(.RIGHT) {
				game_ctx.editor_mode = .None
			}

			switch game_ctx.editor_mode {
			case .PlaceImage:
				if rl.IsMouseButtonPressed(.LEFT) {
					append(
						&game_ctx.images,
						create_image(
							game_ctx^,
							nearest_grid_pos(mouse.xy, grid_spacing),
							game_ctx.selected_asset,
						),
					)
				}
			case .PlaceGround:
				if rl.IsMouseButtonPressed(.LEFT) {
					append(
						&game_ctx.grounds,
						create_ground(
							game_ctx.world_id,
							nearest_grid_pos(mouse.xy, grid_spacing) + UNIT / 2,
						),
					)
				}
			case .None:
			}
		}
	}
}
