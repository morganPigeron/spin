package main

import "core:fmt"
import "core:log"
import "core:mem"
import "core:strings"
import "core:unicode/utf8"

import b2 "vendor:box2d"
import rl "vendor:raylib"
import mu "vendor:microui"

GameCtx :: struct {
	player: Player
}

ShapeType :: enum {
	PLAYER,
	GROUND,
}

Player :: struct {
	body_id:  	  b2.BodyId,
	shape_id: 	  b2.ShapeId,
	extends : 	  b2.Vec2,
	shape_type:   ShapeType,
	jump_speed:   f32,
	move_speed:   f32,
	move_max_velocity :f32,
	is_on_ground: bool,
}

Ground :: struct {
	extends :   b2.Vec2,
	body_id:    b2.BodyId,
	shape_id:   b2.ShapeId,
	shape_type: ShapeType,
}

move_right :: proc(player: ^Player) {
	velocity := b2.Body_GetLinearVelocity(player.body_id).x
	if velocity < 0 || abs(velocity) < player.move_max_velocity {
		b2.Body_ApplyForceToCenter(player.body_id, {player.move_speed, 0}, true)
	}
}

move_left :: proc(player: ^Player) {
	velocity := b2.Body_GetLinearVelocity(player.body_id).x
	if velocity > 0 || abs(velocity) < player.move_max_velocity {
		b2.Body_ApplyForceToCenter(player.body_id, {- player.move_speed, 0}, true)
	}
}

jump :: proc(player: ^Player) {
	if player.is_on_ground {
		b2.Body_ApplyLinearImpulseToCenter(player.body_id, {0, - UNIT * player.jump_speed}, true)
	}
}

player_update :: proc(player: ^Player, contact_events: b2.ContactEvents) {
	for begin in contact_events.beginEvents[:contact_events.beginCount] {
		a := transmute(^ShapeType)b2.Shape_GetUserData(begin.shapeIdA)
		b := transmute(^ShapeType)b2.Shape_GetUserData(begin.shapeIdB)
		
		if a^ == .GROUND && b^ == .PLAYER {
			player.is_on_ground = true
		} else if a^ == .PLAYER && b^ == .GROUND {
			player.is_on_ground = true
		}
	}

	for end in contact_events.endEvents[:contact_events.endCount] {
		a := transmute(^ShapeType)b2.Shape_GetUserData(end.shapeIdA)
		b := transmute(^ShapeType)b2.Shape_GetUserData(end.shapeIdB)
		
		if a^ == .GROUND && b^ == .PLAYER {
			player.is_on_ground = false
		} else if a^ == .PLAYER && b^ == .GROUND {
			player.is_on_ground = false
		}
	}
}

render_player :: proc(player: Player) {
	pos := b2.Body_GetPosition(player.body_id)
	rot := b2.Body_GetRotation(player.body_id)
	rl.DrawRectanglePro(
		{
			pos.x - player.extends.x,
			pos.y - player.extends.y,
			player.extends.x * 2,
			player.extends.y * 2
		},
		{0, 0},
		b2.Rot_GetAngle(rot) * rl.RAD2DEG,
		rl.BLUE
	)
	rl.DrawCircleLinesV(pos.xy, 10, rl.BLACK)
	rl.DrawText(fmt.ctprintf("%.2f", b2.Rot_GetAngle(rot) * rl.RAD2DEG), i32(pos.x), i32(pos.y), 28, rl.RED)
}

UNIT :: 64 // 64 px => 1m

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
	rl.InitWindow(800, 600, "Spin")
	defer rl.CloseWindow()
	rl.SetTargetFPS(60)

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
	
	// ground
	ground : Ground
	ground.shape_type = .GROUND
	ground_body := b2.DefaultBodyDef()
	ground_body.position = {f32(rl.GetScreenWidth())/2 , f32(rl.GetScreenHeight()) + UNIT/2}
	ground_body_id := b2.CreateBody(world_id, ground_body)
	ground.extends = {f32(rl.GetScreenWidth()/2), UNIT/2}
	ground_box := b2.MakeBox(ground.extends.x, ground.extends.y)
	ground_shape := b2.DefaultShapeDef()
	ground_shape.userData = &ground.shape_type
	ground_shape_id := b2.CreatePolygonShape(ground_body_id, ground_shape, ground_box)
	ground.body_id = ground_body_id
	ground.shape_id = ground_shape_id

	// player
	player : Player
	player.shape_type = .PLAYER
	body := b2.DefaultBodyDef()
	body.type = .dynamicBody
	body.position = {f32(rl.GetScreenWidth())/2, -4}
	body.fixedRotation = true
	body_id := b2.CreateBody(world_id, body)
	player.extends = {UNIT/2, UNIT/2}
	dynamic_box := b2.MakeBox(player.extends.x , player.extends.y)
	shape_def := b2.DefaultShapeDef()
	shape_def.userData = &player.shape_type
	shape_def.density = 1
	shape_def.friction = 0.01
	shape_id := b2.CreatePolygonShape(body_id, shape_def, dynamic_box)
	player.body_id = body_id
	player.shape_id = shape_id
	player.jump_speed = 500 * UNIT
	player.move_speed = 100000 * UNIT
	player.move_max_velocity = 2 * UNIT

	camera := rl.Camera2D{}// camera
	camera.zoom = 1

	// game ctx
	game_ctx: GameCtx
	game_ctx.player = player

	for !rl.WindowShouldClose() {
		free_all(context.temp_allocator)
		
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

		player_update(&player, contact_events)

		{ 	//update
			if rl.IsKeyDown(.RIGHT) || rl.IsKeyDown(.D) {
				move_right(&player)
			} else if rl.IsKeyDown(.LEFT) || rl.IsKeyDown(.A) {
				move_left(&player)
			}
			if rl.IsKeyDown(.SPACE) {
				jump(&player)
			}
		}

		{ 	// update mico ui 
			if rl.IsWindowResized() {
				state.screen_width = rl.GetScreenWidth()
				state.screen_height = rl.GetScreenHeight()
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
				rl.BeginMode2D(camera)
				defer rl.EndMode2D()

				render_player(player)
			}

			rl.DrawFPS(10, 10)
			//rl.DrawText(fmt.ctprintf("pos: %v", player.pos), 10, 30, 22, rl.BLACK)
			rl.DrawText(fmt.ctprintf("on ground: %v", player.is_on_ground), 10, 50, 22, rl.BLACK)
			render(ctx)
		}
	}
}
