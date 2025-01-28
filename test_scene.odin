package main

import "core:math"

import b2 "vendor:box2d"
import rl "vendor:raylib"

setup_test_scene :: proc(game_ctx: ^GameCtx) {
    game_ctx.wheel.position = {175 + 20, 175 + 20}
    game_ctx.game_clock = new_game_clock()
    game_ctx.game_clock.time_speed = 10

    game_ctx.boss = create_boss(game_ctx^, {200, f32(UNIT * 2)})
}

update_test_scene :: proc(game_ctx: ^GameCtx) {

    rl.UpdateMusicStream(game_ctx.musics[.MAIN_THEME_2])
    if !rl.IsMusicStreamPlaying(game_ctx.musics[.MAIN_THEME_2]) {
	rl.PlayMusicStream(game_ctx.musics[.MAIN_THEME_2])
	rl.SetMusicVolume(game_ctx.musics[.MAIN_THEME_2], 0.1)
    }
    {
	time_played := rl.GetMusicTimePlayed(game_ctx.musics[.MAIN_THEME_2])
	beat_played := time_played / BPS
	_, decimal := math.split_decimal(beat_played)
	elapsed := decimal * BPS
	game_ctx.main_music_delta_from_beat = elapsed
    }

    contact_events: b2.ContactEvents
    {
	dt := rl.GetFrameTime()
	b2.World_Step(game_ctx.world_id, dt, 4)

	contact_events = b2.World_GetContactEvents(game_ctx.world_id)
    }

    update_player(&game_ctx.player, contact_events)
    update_boss(game_ctx^, &game_ctx.boss, contact_events)
    
    // TODO DEBUG Spawn enemy over time
    /*
    @(static) last_spawn_time : f32 = 0
    last_spawn_time += rl.GetFrameTime()
    if last_spawn_time > 1 {
	last_spawn_time = 0
	append(&game_ctx.enemies, create_enemy(game_ctx^, {200, f32(UNIT * 2)}, .BOY1))
    }
    */

    // Boss
    update_boss(game_ctx^, &game_ctx.boss, contact_events)
    game_ctx.boss.behavior(&game_ctx.boss, game_ctx) 

    // call behavior
    // cleanup if enemy is dead
    for i := 0; i < len(game_ctx.enemies); {
	enemy := &game_ctx.enemies[i]
	update_enemy(game_ctx^, enemy, contact_events)
	enemy.behavior(enemy, game_ctx^)
	if enemy.is_dead {
	    start_wheel(&game_ctx.wheel)
	    cleanup_enemy(enemy^)
	    unordered_remove(&game_ctx.enemies, i)
	} else {
	    i += 1
	}
    }

    for i := 0; i < len(game_ctx.bullets); {
	bullet := &game_ctx.bullets[i]
	update_bullet(bullet)
	if bullet.time_to_live_sec <= 0 { // dont increment, this bullet is cleaned
	    cleanup_bullet(bullet^)
	    unordered_remove(&game_ctx.bullets, i)
	} else { // Bullet still exist 
	    i += 1 // increment the for loop
	    
	    if bullet.shape_type == .BULLET_FROM_BOSS {
		for ground in game_ctx.grounds {
		    ground_pos := b2.Body_GetPosition(ground.body_id)
		    bullet_pos := b2.Body_GetPosition(bullet.body_id)
		    if rl.CheckCollisionPointRec(
			bullet_pos.xy,
			{
			    ground_pos.x - ground.extends.x,
			    ground_pos.y - ground.extends.y,
			    ground.extends.x * 2,
			    ground.extends.y * 2,
			},
		    ) {
			bullet.on_hit(game_ctx, bullet.body_id ,bullet_pos.xy)
			bullet.time_to_live_sec = 0
		    }
		}
	    }
	}
    }

    for &sprite in game_ctx.sprites {
	update_sprite(&sprite)
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
	if rl.IsKeyDown(game_ctx.key_inputs[.SHOOT]) {
	    player_shoot(game_ctx)
	}
    }


    { // check if game is over
	if is_over(&game_ctx.game_clock) || game_ctx.boss.hp <= 0 {
	    change_scene(game_ctx, .End)
	}
    }
    
    update_wheel(game_ctx^, &game_ctx.wheel)
    update_clock(&game_ctx.game_clock)
    update_camera(game_ctx)
}

render_test_scene :: proc(game_ctx: ^GameCtx) {

    {
	rl.BeginMode2D(game_ctx.camera)
	defer rl.EndMode2D()

	for image in game_ctx.background_images {
	    render_image(image)
	}
	
	render_wheel(game_ctx^, game_ctx.wheel)

	for ground in game_ctx.grounds {
	    render_ground(ground)
	}
	
	for image in game_ctx.images {
	    render_image(image)
	}
	
	for &sprite in game_ctx.sprites {
	    render_sprite(&sprite, sprite.position.xy)
	}
	
	for &enemy in game_ctx.enemies {
	    render_enemy(enemy)
	}

	render_boss(game_ctx.boss)
	render_player(game_ctx.player)
	for &bullet in game_ctx.bullets {
	    render_bullet(&bullet)
	}
    }

    rl.DrawFPS(10, 10)
}
