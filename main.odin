package main

import "core:fmt"
import "core:log"
import "core:mem"
import "core:strings"
import "core:unicode/utf8"

import b2 "vendor:box2d"
import rl "vendor:raylib"
import mu "vendor:microui"

ShapeType :: enum {
	PLAYER,
	GROUND,
	ENEMY,
	BULLET_FROM_PLAYER,
}

UNIT :: 64 // 64 px => 1m
INITIAL_SCREEN_WIDTH :: 800
INITIAL_SCREEN_HEIGHT :: 600
main :: proc() {
	context.logger = log.create_console_logger()

	//Tracking allocator
	tracking_allocator: mem.Tracking_Allocator
	mem.tracking_allocator_init(&tracking_allocator, context.allocator)
	context.allocator = mem.tracking_allocator(&tracking_allocator)
	reset_tracking_allocator :: proc(a: ^mem.Tracking_Allocator) -> bool {
		leaks := false
		for key, value in a.allocation_map {
			log.errorf("%v: Leaked %v bytes\n", value.location, value.size)
			leaks = true
		}
		if !leaks {
			log.info("No leak detected\n")
		}
		mem.tracking_allocator_clear(a)
		return leaks
	}
	defer reset_tracking_allocator(&tracking_allocator)
	//Tracking allocator end

	// window init
	rl.SetConfigFlags({.WINDOW_RESIZABLE})
	rl.InitWindow(INITIAL_SCREEN_WIDTH, INITIAL_SCREEN_HEIGHT, "Spin")
	defer rl.CloseWindow()
	rl.SetTargetFPS(60)

	rl.InitAudioDevice()      

	// connect clipboard with microui
	ctx := &state.mu_ctx
	mu.init(ctx, set_clipboard = proc(user_data: rawptr, text: string) -> (ok: bool) {
			cstr := strings.clone_to_cstring(text)
			rl.SetClipboardText(cstr)
			delete(cstr)
			return true
		}, get_clipboard = proc(user_data: rawptr) -> (text: string, ok: bool) {
			cstr := rl.GetClipboardText()
			if cstr != nil {
				text = string(cstr)
				ok = true
			}
			return
		})

	// set context text size
	ctx.text_width = mu.default_atlas_text_width
	ctx.text_height = mu.default_atlas_text_height

	// set texture atlas 
	state.atlas_texture = rl.LoadRenderTexture(
		i32(mu.DEFAULT_ATLAS_WIDTH),
		i32(mu.DEFAULT_ATLAS_HEIGHT),
	)
	defer rl.UnloadRenderTexture(state.atlas_texture)
	image := rl.GenImageColor(
		i32(mu.DEFAULT_ATLAS_WIDTH),
		i32(mu.DEFAULT_ATLAS_HEIGHT),
		rl.Color{0, 0, 0, 0},
	)
	defer rl.UnloadImage(image)
	for alpha, i in mu.default_atlas_alpha {
		x := i % mu.DEFAULT_ATLAS_WIDTH
		y := i / mu.DEFAULT_ATLAS_WIDTH
		color := rl.Color{255, 255, 255, alpha}
		rl.ImageDrawPixel(&image, i32(x), i32(y), color)
	}
	rl.BeginTextureMode(state.atlas_texture)
	rl.UpdateTexture(state.atlas_texture.texture, rl.LoadImageColors(image))
	rl.EndTextureMode()

	// set screen texture
	state.screen_texture = rl.LoadRenderTexture(state.screen_width, state.screen_height)
	defer rl.UnloadRenderTexture(state.screen_texture)

	// box2d init
	b2.SetLengthUnitsPerMeter(UNIT)
	world := b2.DefaultWorldDef()
	world.gravity = {0, 9.81 * UNIT}
	world_id := b2.CreateWorld(world)
	defer b2.DestroyWorld(world_id)
	
	// game ctx
	game_ctx := new_game_ctx()
	defer delete_game_ctx(game_ctx)
	game_ctx.player = create_player(world_id)
	//TODO the pointer to user data need to be always valid
	b2.Shape_SetUserData(game_ctx.player.shape_id, &game_ctx.player.shape_type)
	game_ctx.wheel = create_wheel()
	defer delete_wheel(game_ctx.wheel)
	
	for i in 0 ..< 5 {
		append(&game_ctx.enemies, create_enemy(world_id, {780, f32(UNIT * i)}))
		e := &game_ctx.enemies[len(game_ctx.enemies) - 1]
		b2.Shape_SetUserData(e.shape_id, &e.shape_type)
	}	

	// ground
	game_ctx.ground = create_ground(world_id)
	b2.Shape_SetUserData(game_ctx.ground.shape_id, &game_ctx.ground.shape_type)
	
	{
		camera := rl.Camera2D{}// camera
		camera.zoom = 1
		game_ctx.camera = camera
	}

	for !rl.WindowShouldClose() {
		free_all(context.temp_allocator)

		if rl.IsWindowResized() {
			state.screen_width = rl.GetScreenWidth()
			state.screen_height = rl.GetScreenHeight()
		}
		
		{ // micro ui
			// connect mouse input
			mouse_pos := rl.GetMousePosition()
			mouse_x, mouse_y := i32(mouse_pos.x), i32(mouse_pos.y)
			mu.input_mouse_move(ctx, mouse_x, mouse_y)
			mouse_wheel_pos := rl.GetMouseWheelMoveV()
			mu.input_scroll(ctx, i32(mouse_wheel_pos.x) * 30, i32(mouse_wheel_pos.y) * -30)
			for button_rl, button_mu in mouse_buttons_map {
				switch {
				case rl.IsMouseButtonPressed(button_rl):
					mu.input_mouse_down(ctx, mouse_x, mouse_y, button_mu)
				case rl.IsMouseButtonReleased(button_rl):
					mu.input_mouse_up(ctx, mouse_x, mouse_y, button_mu)
				}
			}

			// connect keyboard input
			for keys_rl, key_mu in key_map {
				for key_rl in keys_rl {
					switch {
					case key_rl == .KEY_NULL:
					// ignore
					case rl.IsKeyPressed(key_rl):
						mu.input_key_down(ctx, key_mu)
					case rl.IsKeyReleased(key_rl):
						mu.input_key_up(ctx, key_mu)
					}
				}
			}

			// connect text typed 
			{
				buf: [512]byte
				n: int
				for n < len(buf) {
					c := rl.GetCharPressed()
					if c == 0 {
						break
					}
					b, w := utf8.encode_rune(c)
					n += copy(buf[n:], b[:w])
				}
				mu.input_text(ctx, string(buf[:n]))
			}
		}
		

		contact_events: b2.ContactEvents
		{
			dt := rl.GetFrameTime()
			b2.World_Step(world_id, dt, 4)

			contact_events = b2.World_GetContactEvents(world_id)
		}

		update_player(&game_ctx.player, contact_events)
		for &enemy in game_ctx.enemies {
			update_enemy(&enemy, contact_events)
			enemy.behavior(&enemy, game_ctx)
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
		}

		update_wheel(&game_ctx.wheel)

		{ 	// update mico ui 
			if rl.IsWindowResized() {
				rl.UnloadRenderTexture(state.screen_texture)
				state.screen_texture = rl.LoadRenderTexture(
					state.screen_width,
					state.screen_height,
				)
			}
			mu.begin(ctx)
			all_windows(ctx, &game_ctx)
			mu.end(ctx)
		}

		{ 	//rendering
			rl.BeginDrawing()
			defer rl.EndDrawing()
			rl.ClearBackground(rl.RAYWHITE)

			{
				rl.BeginMode2D(game_ctx.camera)
				defer rl.EndMode2D()

				render_ground(game_ctx.ground)
				for &enemy in game_ctx.enemies {
					render_enemy(enemy)
				}
				render_wheel(game_ctx.wheel)
				render_player(game_ctx.player)
			}

			rl.DrawFPS(10, 10)
			render(ctx)
		}
	}
}
