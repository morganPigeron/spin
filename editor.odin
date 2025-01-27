package main

import b2 "vendor:box2d"
import rl "vendor:raylib"

import "core:log"
import "core:math"
import "core:os"

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
	    game_ctx.camera.zoom += scroll * rl.GetFrameTime() * 10
	}

	update_sprite(&game_ctx.editor_selected_sprite)
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
	    rl.DrawLineEx(
		{-INITIAL_SCREEN_WIDTH / 2, -INITIAL_SCREEN_HEIGHT / 2} + cam,
		{INITIAL_SCREEN_WIDTH / 2, -INITIAL_SCREEN_HEIGHT / 2} + cam,
		4,
		rl.PURPLE,
	    )
	    rl.DrawLineEx(
		{INITIAL_SCREEN_WIDTH / 2, -INITIAL_SCREEN_HEIGHT / 2} + cam,
		{INITIAL_SCREEN_WIDTH / 2, INITIAL_SCREEN_HEIGHT / 2} + cam,
		4,
		rl.PURPLE,
	    )
	    rl.DrawLineEx(
		{INITIAL_SCREEN_WIDTH / 2, INITIAL_SCREEN_HEIGHT / 2} + cam,
		{-INITIAL_SCREEN_WIDTH / 2, INITIAL_SCREEN_HEIGHT / 2} + cam,
		4,
		rl.PURPLE,
	    )
	    rl.DrawLineEx(
		{-INITIAL_SCREEN_WIDTH / 2, INITIAL_SCREEN_HEIGHT / 2} + cam,
		{-INITIAL_SCREEN_WIDTH / 2, -INITIAL_SCREEN_HEIGHT / 2} + cam,
		4,
		rl.PURPLE,
	    )

	    pos: rl.Vector2 = nearest_grid_pos(mouse.xy, grid_spacing)
	    switch game_ctx.editor_mode {
	    case .PlaceBackground:
		fallthrough
	    case .PlaceImage:
		rl.DrawTextureV(game_ctx.assets[game_ctx.selected_asset], pos, rl.WHITE)
	    case .PlaceSprite:
		render_sprite(&game_ctx.editor_selected_sprite, pos)
	    case .PlaceGround:
		rl.DrawRectangleV(pos, {UNIT, UNIT}, rl.BROWN)
	    case .Remove:

	    case .None:
	    }
	}

	{ 	//screen space
	    BUTTON_SIZE: rl.Vector2 : {150, 30}
	    PADDING :: 30
	    if game_ctx.editor_mode == .None {
		button_rect: rl.Rectangle = {
		    screen.x - BUTTON_SIZE.x - 150,
		    150,
		    BUTTON_SIZE.x,
		    BUTTON_SIZE.y,
		}
		if rl.GuiButton(button_rect, "place ground") {
		    game_ctx.editor_mode = .PlaceGround
		    grid_spacing = UNIT
		}

		button_rect.y += PADDING + button_rect.height
		if rl.GuiButton(button_rect, "place plant") {
		    game_ctx.editor_mode = .PlaceImage
		    game_ctx.selected_asset = .PLANT
		    grid_spacing = 8
		}

		button_rect.y += PADDING + button_rect.height
		if rl.GuiButton(button_rect, "place cubicle") {
		    game_ctx.editor_mode = .PlaceImage
		    game_ctx.selected_asset = .CUBICLE
		    grid_spacing = 8
		}

		button_rect.y += PADDING + button_rect.height
		if rl.GuiButton(button_rect, "place WALL1") {
		    game_ctx.editor_mode = .PlaceBackground
		    game_ctx.selected_asset = .WALL1
		    grid_spacing = 64
		}
		
		button_rect.y += PADDING + button_rect.height
		if rl.GuiButton(button_rect, "place WALL2") {
		    game_ctx.editor_mode = .PlaceBackground
		    game_ctx.selected_asset = .WALL2
		    grid_spacing = 64
		}

		button_rect.y += PADDING + button_rect.height
		if rl.GuiButton(button_rect, "place printer") {
		    game_ctx.editor_mode = .PlaceSprite
		    grid_spacing = 8
		    game_ctx.editor_selected_sprite = create_sprite(game_ctx^, {0, 0}, .PRINTER)
		}

		button_rect.y += PADDING + button_rect.height
		if rl.GuiButton(button_rect, "place stappler") {
		    game_ctx.editor_mode = .PlaceSprite
		    grid_spacing = 8
		    game_ctx.editor_selected_sprite = create_sprite(game_ctx^, {0, 0}, .STAPPLER)
		}

		button_rect.y += PADDING + button_rect.height
		if rl.GuiButton(button_rect, "remove element") {
		    game_ctx.editor_mode = .Remove
		}

		button_rect.y += PADDING + button_rect.height
		if rl.GuiButton(button_rect, "save") {
		    save := serialize_ctx_v3(game_ctx)
		    defer delete(save)
		    os.write_entire_file("save.spin", save)
		}

		button_rect.y += PADDING + button_rect.height
		if rl.GuiButton(button_rect, "load") {
		    save, ok := os.read_entire_file_from_filename("save.spin")
		    defer delete(save)
		    if ok {
			deserialize_ctx(game_ctx, save)
		    }
		}
	    } else if rl.IsMouseButtonPressed(.RIGHT) {
		game_ctx.editor_mode = .None
	    }

	    switch game_ctx.editor_mode {
	    case .PlaceBackground:
		if rl.IsMouseButtonPressed(.LEFT) {
		    append(
			    &game_ctx.background_images,
			create_image(
			    game_ctx^,
			    nearest_grid_pos(mouse.xy, grid_spacing),
			    game_ctx.selected_asset,
			),
		    )
		}
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
	    case .PlaceSprite:
		if rl.IsMouseButtonPressed(.LEFT) {
		    append(&game_ctx.sprites, game_ctx.editor_selected_sprite)
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
	    case .Remove:
		if rl.IsMouseButtonPressed(.LEFT) {

		    {
			i := 0
			lenght := len(game_ctx.grounds)
			for i < lenght {
			    if is_overlapping_ground(mouse.xy, game_ctx.grounds[i]) {
				log.debugf("overlap %v", game_ctx.grounds[i].body_id)
				delete_ground(game_ctx.grounds[i])
				unordered_remove(&game_ctx.grounds, i)
				lenght -= 1
			    } else {
				i += 1
			    }
			}
		    }

		    {
			i := 0
			lenght := len(game_ctx.images)
			for i < lenght {
			    if is_overlapping_image(mouse.xy, game_ctx.images[i]) {
				log.debugf("overlap %v", game_ctx.images[i].asset)
				unordered_remove(&game_ctx.images, i)
				lenght -= 1
			    } else {
				i += 1
			    }
			}
		    }
		    
		    {
			i := 0
			lenght := len(game_ctx.background_images)
			for i < lenght {
			    if is_overlapping_image(mouse.xy, game_ctx.background_images[i]) {
				log.debugf("overlap %v", game_ctx.background_images[i].asset)
				unordered_remove(&game_ctx.background_images, i)
				lenght -= 1
			    } else {
				i += 1
			    }
			}
		    }

		    {
			i := 0
			lenght := len(game_ctx.sprites)
			for i < lenght {
			    if is_overlapping_sprite(mouse.xy, game_ctx.sprites[i]) {
				unordered_remove(&game_ctx.sprites, i)
				lenght -= 1
			    } else {
				i += 1
			    }
			}
		    }

		}
	    case .None:
	    }
	}
    }
}
