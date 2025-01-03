package main

import "core:fmt"
import "core:log"
import "core:mem"
import "core:strings"
import b2 "vendor:box2d"
import rl "vendor:raylib"

Player :: struct {
	pos:          rl.Vector2,
	collision:    rl.Rectangle,
	speed:        f32,
	is_on_ground: bool,
}

move_right :: proc(player: ^Player) {
}

move_left :: proc(player: ^Player) {
}

jump :: proc(player: ^Player) {
}

player_update :: proc(player: ^Player) {
}

render_player :: proc(player: Player) {
	rl.DrawRectangleRec(player.collision, rl.BLUE)
	rl.DrawCircleLinesV(player.pos, 1, rl.BLACK)
}

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

	// box2d init
	world := b2.DefaultWorldDef()
	world.gravity = {0, 10}
	
	camera := rl.Camera2D{}// camera
	camera.zoom = 1
	//rl.DisableCursor()

	// player
	player := Player {
		pos          = {0, 0},
		collision    = rl.Rectangle{0, 0, 32, 64},
		speed        = 9.81,
		is_on_ground = false,
	}

	for !rl.WindowShouldClose() {
		free_all(context.temp_allocator)

		{ 	//update
			if rl.IsKeyDown(.RIGHT) || rl.IsKeyDown(.D) {
				move_right(&player)
			} else if rl.IsKeyDown(.LEFT) || rl.IsKeyDown(.Q) {
				move_left(&player)
			} else if rl.IsKeyDown(.SPACE) {
				jump(&player)
			}
			player_update(&player)

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
			rl.DrawText(fmt.ctprintf("pos: %v", player.pos), 10, 30, 22, rl.BLACK)
			rl.DrawText(fmt.ctprintf("on ground: %v", player.is_on_ground), 10, 50, 22, rl.BLACK)
		}
	}
}
