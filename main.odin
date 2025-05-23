package main

import "core:fmt"
import "core:log"
import "core:mem"
import "core:strings"
import "core:time"
import "core:unicode/utf8"

import b2 "vendor:box2d"
import mu "vendor:microui"
import rl "vendor:raylib"

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
    defer rl.CloseAudioDevice()
    if !rl.IsAudioDeviceReady() {
	log.error("audio device not ready")
    }
    load_sounds()
    defer delete_sounds()

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

    // game ctx
    game_ctx := new_game_ctx()
    defer delete_game_ctx(game_ctx)

    // box2d init
    {
	b2.SetLengthUnitsPerMeter(UNIT)
	world := b2.DefaultWorldDef()
	world.gravity = {0, 9.81 * UNIT}
	game_ctx.world_id = b2.CreateWorld(world)
    }

    setup_common_scene(&game_ctx)
    setup_menu_scene(&game_ctx)

    mean_time: f64 = 0
    last_mean_time: f64 = 0
    mean_time_counter := 0

    for !rl.WindowShouldClose() {
	t0 := time.Stopwatch{}
	time.stopwatch_start(&t0)

	free_all(context.temp_allocator)

	if rl.IsWindowResized() {
	    state.screen_width = rl.GetScreenWidth()
	    state.screen_height = rl.GetScreenHeight()
	    if !game_ctx.is_editor {
		game_ctx.camera.zoom = min(
		    f32(state.screen_width) / INITIAL_SCREEN_WIDTH,
		    f32(state.screen_height) / INITIAL_SCREEN_HEIGHT,
		)
	    }
	}

	{ 	// micro ui
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

	switch game_ctx.current_scene {
	case .Test:
	    update_test_scene(&game_ctx)
	case .Menu:
	    update_menu_scene(&game_ctx)
	case .End:
	    update_end_scene(&game_ctx)
	}
	update_editor(&game_ctx)

	{
	    rl.BeginDrawing()


	    rl.ClearBackground(rl.RAYWHITE)

	    switch game_ctx.current_scene {
	    case .Test:
		render_test_scene(&game_ctx)
	    case .Menu:
		render_menu_scene(&game_ctx)
	    case .End:
		render_end_scene(&game_ctx)
	    }
	    render_editor(&game_ctx)

	    if game_ctx.current_scene == .Menu {
		render(ctx)
	    }

	    if (game_ctx.is_editor) {
		dur := time.stopwatch_duration(t0)
		millis := time.duration_milliseconds(dur)
		if mean_time_counter < 100 {
		    mean_time_counter += 1
		    mean_time += millis
		} else {
		    last_mean_time = mean_time / f64(mean_time_counter)
		    mean_time_counter = 0
		    mean_time = 0
		}
		rl.DrawText(fmt.ctprintf("%2.2f ms", last_mean_time), 10, 30, 20, rl.RED)
		rl.DrawText(fmt.ctprintf("%2.2f ms", millis), 10, 50, 20, rl.RED)
	    }
	    rl.EndDrawing()

	}
    }
}
