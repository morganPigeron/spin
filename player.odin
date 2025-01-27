package main

import "core:fmt"
import "core:log"
import "core:math"
import "core:mem"
import "core:strings"
import "core:unicode/utf8"

import b2 "vendor:box2d"
import rl "vendor:raylib"

Player :: struct {
    body_id:                    b2.BodyId,
    shape_id:                   b2.ShapeId,
    extends:                    b2.Vec2,
    shape_type:                 ShapeType,
    jump_speed:                 f32,
    move_speed:                 f32,
    move_max_velocity:          f32,
    is_on_ground:               bool,
    last_time_still_vertically: f32,
    image:                      Image,
    last_direction_facing:      rl.Vector2,
    direction:                  rl.Vector2,
    last_time_jumped:           f32,
    last_time_shooting:         f32,
    walk_sound:                 rl.Music,
}

player_shoot :: proc(ctx: ^GameCtx) {
    DEBOUNCE :: 0.3
    if ctx.player.last_time_shooting >= DEBOUNCE {
	ctx.player.last_time_shooting = 0

	direction: rl.Vector2 = ctx.player.last_direction_facing
	if rl.IsKeyDown(ctx.key_inputs[.RIGHT]) {
	    direction.x = 1
	} else if rl.IsKeyDown(ctx.key_inputs[.LEFT]) {
	    direction.x = -1
	}

	if rl.IsKeyDown(ctx.key_inputs[.UP]) {
	    direction.y = -1
	} else if rl.IsKeyDown(ctx.key_inputs[.DOWN]) {
	    direction.y = 1
	}

	spawn_player_bullet(ctx, b2.Body_GetPosition(ctx.player.body_id), direction)
    }
}

player_move_right :: proc(player: ^Player) {
    player.last_direction_facing = {1, 0}
    velocity := b2.Body_GetLinearVelocity(player.body_id).x
    if velocity < 0 || abs(velocity) < player.move_max_velocity {
	b2.Body_ApplyForceToCenter(player.body_id, {player.move_speed, 0}, true)
    }
    player.direction = {1,0}
}

player_move_left :: proc(player: ^Player) {
    player.last_direction_facing = {-1, 0}
    velocity := b2.Body_GetLinearVelocity(player.body_id).x
    if velocity > 0 || abs(velocity) < player.move_max_velocity {
	b2.Body_ApplyForceToCenter(player.body_id, {-player.move_speed, 0}, true)
    }
    player.direction = {-1,0}
}

player_jump :: proc(player: ^Player) {
    DEBOUNCE :: 0.2
    if player.is_on_ground && player.last_time_jumped > DEBOUNCE {
	b2.Body_ApplyLinearImpulseToCenter(player.body_id, {0, -UNIT * player.jump_speed}, true)
	player.last_time_jumped = 0
    }
}

update_player :: proc(player: ^Player, contact_events: b2.ContactEvents) {

    //update all timer : 
    player.last_time_shooting += rl.GetFrameTime()
    player.last_time_jumped += rl.GetFrameTime()

    //DEBUG TODO remove that
    @(static) min_vel: f32 = 341232343
    @(static) max_vel: f32 = -1

    velocity := b2.Body_GetLinearVelocity(player.body_id)
    player_velocity := math.abs(velocity.y)
    jump_tolerance :: 0.01
    is_still_vertically := player_velocity <= jump_tolerance

    if is_still_vertically {
	player.last_time_still_vertically += rl.GetFrameTime()
    } else {
	player.last_time_still_vertically = 0
    }

    if (is_still_vertically || player.is_on_ground || math.abs(velocity.y) <= 100) &&
	math.abs(velocity.x) > 0.1 {
	    if !rl.IsMusicStreamPlaying(player.walk_sound) {
		rl.PlayMusicStream(player.walk_sound)
		rl.SetMusicVolume(player.walk_sound, 0.1)
	    }
	} else {
	    rl.PauseMusicStream(player.walk_sound)
	}

    for begin in contact_events.beginEvents[:contact_events.beginCount] {
	a := transmute(^ShapeType)b2.Shape_GetUserData(begin.shapeIdA)
	b := transmute(^ShapeType)b2.Shape_GetUserData(begin.shapeIdB)

	if a^ == .GROUND && b^ == .PLAYER && is_still_vertically {
	    player.is_on_ground = true
	} else if a^ == .PLAYER && b^ == .GROUND && is_still_vertically {
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

    TIME_TO_RESET_JUMP :: 0.2
    if player.last_time_still_vertically > TIME_TO_RESET_JUMP {
	player.is_on_ground = true
    }

    pos := b2.Body_GetPosition(player.body_id)
    player.image.pos =
	pos - ({f32(player.image.texture.width), f32(player.image.texture.height)} / 2)

    rl.UpdateMusicStream(player.walk_sound)
}

render_player :: proc(player: Player) {
    pos := b2.Body_GetPosition(player.body_id)
    rot := b2.Body_GetRotation(player.body_id)

    //render_image(player.image)
    render_image_direction(player.image, player.direction) 
    rl.DrawCircleLinesV(pos.xy, 10, rl.BLACK)
}

create_player :: proc(ctx: GameCtx) -> (player: Player) {
    player.shape_type = .PLAYER
    body := b2.DefaultBodyDef()
    body.type = .dynamicBody
    body.position = {f32(rl.GetScreenWidth()) / 2, -4}
    body.fixedRotation = true
    body_id := b2.CreateBody(ctx.world_id, body)
    player.extends = {UNIT / 4, UNIT / 4}
    dynamic_box := b2.Capsule {
	center1 = {0, 0},
	center2 = {0, player.extends.y},
	radius  = player.extends.x,
    }
    shape_def := b2.DefaultShapeDef()
    shape_def.density = 1
    shape_def.friction = 0.07
    shape_def.enableHitEvents = true
    shape_id := b2.CreateCapsuleShape(body_id, shape_def, dynamic_box)
    player.body_id = body_id
    player.shape_id = shape_id
    player.jump_speed = 91 * UNIT
    player.move_speed = 31572 * UNIT
    player.move_max_velocity = 3 * UNIT
    b2.Shape_SetUserData(shape_id, &ShapeTypePlayer)
    player.image = create_image(ctx, body.position, .CHARACTER)
    player.walk_sound = SoundsList[.WALKING_FX_1]
    player.direction = {1,0}
    return
}
