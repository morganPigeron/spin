package main

import "core:fmt"
import "core:log"
import "core:math"
import "core:mem"
import "core:strings"
import "core:unicode/utf8"

import b2 "vendor:box2d"
import rl "vendor:raylib"

/*
TODO

X Boss shoot printer,
/ when printer hit floor or player, it become a employe, if it touch player, additional damage is taken
  when employe touch player, it advance time
X when player kill employee, it spin the wheel

X when boss is dead game is over
X when no more time left, game is over
*/

BOSS_HP :: 1000

Boss :: struct {
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
    behavior:                   proc(self: ^Boss, ctx: ^GameCtx),
    hp:                         f32,
    is_dead:                    bool,  
}

boss_behavior :: proc(self: ^Boss, ctx: ^GameCtx) {
    player_pos := b2.Body_GetPosition(ctx.player.body_id)
    self_pos := b2.Body_GetPosition(self.body_id)

    boss_shoot(ctx, self_pos, rl.Vector2Normalize(player_pos - self_pos)) 
    
    /*
    if self_pos.x > player_pos.x {
	boss_move_left(self)
    } else {
	boss_move_right(self)
    }

    if self_pos.y > player_pos.y {
	boss_jump(self)
    }
    */
}

boss_shoot :: proc(ctx: ^GameCtx, from: rl.Vector2, direction: rl.Vector2) {
    DEBOUNCE :: 2.5
    if ctx.boss.last_time_shooting >= DEBOUNCE {
	ctx.boss.last_time_shooting = 0
	spawn_boss_bullet(ctx, from, direction)
    }
}

boss_move_right :: proc(boss: ^Boss) {
    boss.last_direction_facing = {1, 0}
    velocity := b2.Body_GetLinearVelocity(boss.body_id).x
    if velocity < 0 || abs(velocity) < boss.move_max_velocity {
	b2.Body_ApplyForceToCenter(boss.body_id, {boss.move_speed, 0}, true)
    }
    boss.direction = {1,0}
}

boss_move_left :: proc(boss: ^Boss) {
    boss.last_direction_facing = {-1, 0}
    velocity := b2.Body_GetLinearVelocity(boss.body_id).x
    if velocity > 0 || abs(velocity) < boss.move_max_velocity {
	b2.Body_ApplyForceToCenter(boss.body_id, {-boss.move_speed, 0}, true)
    }
    boss.direction = {-1,0}
}

boss_jump :: proc(boss: ^Boss) {
    DEBOUNCE :: 0.2
    if boss.is_on_ground && boss.last_time_jumped > DEBOUNCE {
	b2.Body_ApplyLinearImpulseToCenter(boss.body_id, {0, -UNIT * boss.jump_speed}, true)
	boss.last_time_jumped = 0
    }
}

update_boss :: proc(ctx: GameCtx, boss: ^Boss, contact_events: b2.ContactEvents) {

    //update all timer : 
    boss.last_time_shooting += rl.GetFrameTime()
    boss.last_time_jumped += rl.GetFrameTime()

    velocity := b2.Body_GetLinearVelocity(boss.body_id)
    boss_velocity := math.abs(velocity.y)
    jump_tolerance :: 0.01
    is_still_vertically := boss_velocity <= jump_tolerance

    if is_still_vertically {
	boss.last_time_still_vertically += rl.GetFrameTime()
    } else {
	boss.last_time_still_vertically = 0
    }

    for begin in contact_events.beginEvents[:contact_events.beginCount] {
	a := transmute(^ShapeType)b2.Shape_GetUserData(begin.shapeIdA)
	b := transmute(^ShapeType)b2.Shape_GetUserData(begin.shapeIdB)

	if a^ == .GROUND && b^ == .BOSS && is_still_vertically {
	    boss.is_on_ground = true
	} else if a^ == .BOSS && b^ == .GROUND && is_still_vertically {
	    boss.is_on_ground = true
	}
    }

    for end in contact_events.endEvents[:contact_events.endCount] {
	a := transmute(^ShapeType)b2.Shape_GetUserData(end.shapeIdA)
	b := transmute(^ShapeType)b2.Shape_GetUserData(end.shapeIdB)

	if a^ == .GROUND && b^ == .BOSS {
	    boss.is_on_ground = false
	} else if a^ == .BOSS && b^ == .GROUND {
	    boss.is_on_ground = false
	}
    }

    TIME_TO_RESET_JUMP :: 0.2
    if boss.last_time_still_vertically > TIME_TO_RESET_JUMP {
	boss.is_on_ground = true
    }

    pos := b2.Body_GetPosition(boss.body_id)
    
    { 	//test hit
	for bullet in ctx.bullets {
	    if bullet.shape_type == .BULLET_FROM_PLAYER && rl.CheckCollisionPointRec(
		b2.Body_GetPosition(bullet.body_id).xy,
		{
		    pos.x - boss.extends.x,
		    pos.y - boss.extends.y,
		    boss.extends.x * 2,
		    boss.extends.y * 2,
		},
	    ) {
		boss.hp -= 10
	    }
	}
    }

    if boss.hp <= 0 {
	boss.is_dead = true
    }

    scale :: 2
    boss.image.pos =
	pos - ({f32(boss.image.texture.width * scale), f32(boss.image.texture.height * scale)} / 2)
}

render_boss :: proc(boss: Boss) {
    pos := b2.Body_GetPosition(boss.body_id)
    rot := b2.Body_GetRotation(boss.body_id)

    render_image_direction_scale(boss.image, boss.direction, 2) 
    rl.DrawCircleLinesV(pos.xy, 10, rl.BLACK)

    top_left := pos.xy - {boss.extends.x, boss.extends.y * 2 + 10}

    rl.DrawRectangle(i32(top_left.x), i32(top_left.y), i32(boss.extends.x * 2), 4, rl.BLACK)
    rl.DrawRectangle(
	i32(top_left.x),
	i32(top_left.y),
	i32(f32(boss.hp) * f32(boss.extends.x * 2.0) / f32(BOSS_HP)),
	4,
	rl.RED,
    )
}

create_boss :: proc(ctx: GameCtx, pos: [2]f32) -> (boss: Boss) {
    boss.shape_type = .BOSS
    body := b2.DefaultBodyDef()
    body.type = .dynamicBody
    body.position = pos.xy
    body.fixedRotation = true
    body_id := b2.CreateBody(ctx.world_id, body)
    boss.extends = {UNIT / 2, UNIT / 2}
    dynamic_box := b2.Capsule {
	center1 = {0, 0},
	center2 = {0, boss.extends.y},
	radius  = boss.extends.x,
    }
    shape_def := b2.DefaultShapeDef()
    shape_def.density = 1
    shape_def.friction = 0.07
    shape_def.enableHitEvents = true
    shape_id := b2.CreateCapsuleShape(body_id, shape_def, dynamic_box)
    boss.body_id = body_id
    boss.shape_id = shape_id
    boss.jump_speed = 91 * UNIT
    boss.move_speed = 31572 * UNIT
    boss.move_max_velocity = 3 * UNIT
    b2.Shape_SetUserData(shape_id, &ShapeTypeBoss)
    boss.image = create_image(ctx, body.position, .BOY1)
    boss.walk_sound = SoundsList[.WALKING_1]
    boss.direction = {1,0}
    boss.hp = BOSS_HP
    boss.behavior = boss_behavior
    return
}
