package main

import b2 "vendor:box2d"
import rl "vendor:raylib"

setup_common_scene :: proc(game_ctx: ^GameCtx) {
    game_ctx.player = create_player(game_ctx.world_id)
	//TODO the pointer to user data need to be always valid
	b2.Shape_SetUserData(game_ctx.player.shape_id, &game_ctx.player.shape_type)
	game_ctx.wheel = create_wheel()
    
	for i in 0 ..< 5 {
		append(&game_ctx.enemies, create_enemy(game_ctx.world_id, {780, f32(UNIT * i)}))
		e := &game_ctx.enemies[len(game_ctx.enemies) - 1]
		b2.Shape_SetUserData(e.shape_id, &e.shape_type)
	}	

	// ground
	game_ctx.ground = create_ground(game_ctx.world_id)
	b2.Shape_SetUserData(game_ctx.ground.shape_id, &game_ctx.ground.shape_type)
	
	{
		camera := rl.Camera2D{}// camera
		camera.zoom = 1
		game_ctx.camera = camera
	}

}