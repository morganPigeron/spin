package main

import b2 "vendor:box2d"
import rl "vendor:raylib"

import "core:os"

setup_common_scene :: proc(game_ctx: ^GameCtx) {
    game_ctx.player = create_player(game_ctx^)
    game_ctx.wheel = create_wheel(game_ctx^)   
    {
	camera := rl.Camera2D{}// camera
	camera.zoom = 1
	game_ctx.camera = camera
    }

    {
	save := #load("save.spin")
	deserialize_ctx(game_ctx, save)
    }

}
