package main

import b2 "vendor:box2d"
import rl "vendor:raylib"

import "core:os"

setup_common_scene :: proc(game_ctx: ^GameCtx) {
    game_ctx.player = create_player(game_ctx^)
    game_ctx.wheel = create_wheel(game_ctx^)
    
    //append(&game_ctx.enemies, create_enemy(game_ctx^, {200, f32(UNIT * 2)}, .BOY1))
    //append(&game_ctx.enemies, create_enemy(game_ctx^, {230, f32(UNIT * 2)}, .GIRL1))
    //append(&game_ctx.enemies, create_enemy(game_ctx^, {260, f32(UNIT * 2)}, .GIRL2))

    // ground
    //game_ctx.ground = create_ground(game_ctx.world_id)
    
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
