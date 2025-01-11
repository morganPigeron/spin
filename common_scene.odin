package main

import b2 "vendor:box2d"
import rl "vendor:raylib"

setup_common_scene :: proc(game_ctx: ^GameCtx) {
    game_ctx.player = create_player(game_ctx.world_id)
	game_ctx.wheel = create_wheel()
    
	for i in 0 ..< 5 {
		append(&game_ctx.enemies, create_enemy(game_ctx.world_id, {780, f32(UNIT * i)}))
	}	

	// ground
	//game_ctx.ground = create_ground(game_ctx.world_id)
	
	{
		camera := rl.Camera2D{}// camera
		camera.zoom = 1
		game_ctx.camera = camera
	}

}