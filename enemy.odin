package main

import "core:fmt"
import "core:log"
import "core:mem"
import "core:strings"
import "core:unicode/utf8"

import b2 "vendor:box2d"
import rl "vendor:raylib"

Enemy :: struct {
	hp:                int,
	is_dead:           bool,
	body_id:           b2.BodyId,
	shape_id:          b2.ShapeId,
	extends:           b2.Vec2,
	shape_type:        ShapeType,
	jump_speed:        f32,
	move_speed:        f32,
	move_max_velocity: f32,
	is_on_ground:      bool,
	image:             Image,
	behavior:          proc(self: ^Enemy, ctx: GameCtx),
}

simple_behavior :: proc(self: ^Enemy, ctx: GameCtx) {
	player_pos := b2.Body_GetPosition(ctx.player.body_id)
	self_pos := b2.Body_GetPosition(self.body_id)

	if self_pos.x > player_pos.x {
		enemy_move_left(self)
	} else {
		enemy_move_right(self)
	}

	if self_pos.y > player_pos.y {
		enemy_jump(self)
	}
}

enemy_move_right :: proc(enemy: ^Enemy) {
	velocity := b2.Body_GetLinearVelocity(enemy.body_id).x
	if velocity < 0 || abs(velocity) < enemy.move_max_velocity {
		b2.Body_ApplyForceToCenter(enemy.body_id, {enemy.move_speed, 0}, true)
	}
}

enemy_move_left :: proc(enemy: ^Enemy) {
	velocity := b2.Body_GetLinearVelocity(enemy.body_id).x
	if velocity > 0 || abs(velocity) < enemy.move_max_velocity {
		b2.Body_ApplyForceToCenter(enemy.body_id, {-enemy.move_speed, 0}, true)
	}
}

enemy_jump :: proc(enemy: ^Enemy) {
	if enemy.is_on_ground {
		b2.Body_ApplyLinearImpulseToCenter(enemy.body_id, {0, -UNIT * enemy.jump_speed}, true)
	}
}

update_enemy :: proc(ctx: GameCtx, enemy: ^Enemy, contact_events: b2.ContactEvents) {
	pos := b2.Body_GetPosition(enemy.body_id)
	if !enemy.is_dead {

		for begin in contact_events.beginEvents[:contact_events.beginCount] {
			a := transmute(^ShapeType)b2.Shape_GetUserData(begin.shapeIdA)
			b := transmute(^ShapeType)b2.Shape_GetUserData(begin.shapeIdB)

			if a^ == .GROUND && b^ == .ENEMY {
				enemy.is_on_ground = true
			} else if a^ == .ENEMY && b^ == .GROUND {
				enemy.is_on_ground = true
			}
		}

		for end in contact_events.endEvents[:contact_events.endCount] {
			a := transmute(^ShapeType)b2.Shape_GetUserData(end.shapeIdA)
			b := transmute(^ShapeType)b2.Shape_GetUserData(end.shapeIdB)

			if a^ == .GROUND && b^ == .ENEMY {
				enemy.is_on_ground = false
			} else if a^ == .ENEMY && b^ == .GROUND {
				enemy.is_on_ground = false
			}
		}


		{ 	//test hit
			for bullet in ctx.bullets {
				if rl.CheckCollisionPointRec(
					b2.Body_GetPosition(bullet.body_id).xy,
					{
						pos.x - enemy.extends.x,
						pos.y - enemy.extends.y,
						enemy.extends.x * 2,
						enemy.extends.y * 2,
					},
				) {
					enemy.hp -= 10
				}
			}
		}

		if enemy.hp <= 0 {
			enemy.is_dead = true
		}
	}

	enemy.image.pos = pos - ({f32(enemy.image.texture.width), f32(enemy.image.texture.height)} / 2)
}

render_enemy :: proc(enemy: Enemy) {
	pos := b2.Body_GetPosition(enemy.body_id)
	rot := b2.Body_GetRotation(enemy.body_id)

	render_image(enemy.image)

	rl.DrawCircleLinesV(pos.xy, 10, rl.BLACK)

	top_left := pos.xy - {enemy.extends.x, enemy.extends.y * 2 + 10}

	rl.DrawRectangle(i32(top_left.x), i32(top_left.y), i32(enemy.extends.x * 2), 4, rl.BLACK)
	rl.DrawRectangle(
		i32(top_left.x),
		i32(top_left.y),
		i32(f32(enemy.hp) * (enemy.extends.x * 2) / 100),
		4,
		rl.RED,
	)
}

create_enemy :: proc(ctx: GameCtx, pos: rl.Vector2, visual: Assets) -> (enemy: Enemy) {
	enemy.shape_type = .ENEMY
	body := b2.DefaultBodyDef()
	body.type = .dynamicBody
	body.position = pos.xy
	body.fixedRotation = true
	body_id := b2.CreateBody(ctx.world_id, body)
	enemy.extends = {UNIT / 4, UNIT / 4}
	dynamic_box := b2.Capsule {
		center1 = {0, 0},
		center2 = {0, enemy.extends.y},
		radius  = enemy.extends.x,
	}
	shape_def := b2.DefaultShapeDef()
	shape_def.enableHitEvents = true
	shape_def.density = 1
	shape_def.friction = 0.07
	shape_id := b2.CreateCapsuleShape(body_id, shape_def, dynamic_box)
	enemy.body_id = body_id
	enemy.shape_id = shape_id
	enemy.jump_speed = 91 * UNIT
	enemy.move_speed = 31572 * UNIT
	enemy.move_max_velocity = 1 * UNIT
	enemy.behavior = simple_behavior
	enemy.image = create_image(ctx, body.position, visual)
	enemy.hp = 100
	b2.Shape_SetUserData(shape_id, &ShapeTypeEnemy)
	return
}

cleanup_enemy :: proc(enemy: Enemy) {
	b2.DestroyBody(enemy.body_id)
}
