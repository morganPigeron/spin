package main

import "core:fmt"
import "core:log"
import "core:mem"
import "core:strings"
import "core:unicode/utf8"

import b2 "vendor:box2d"
import rl "vendor:raylib"

Enemy :: struct {
	body_id:           b2.BodyId,
	shape_id:          b2.ShapeId,
	extends:           b2.Vec2,
	shape_type:        ShapeType,
	jump_speed:        f32,
	move_speed:        f32,
	move_max_velocity: f32,
	is_on_ground:      bool,
}

update_enemy :: proc(enemy: ^Enemy, contact_events: b2.ContactEvents) {
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
}

render_enemy :: proc(enemy: Enemy) {
	pos := b2.Body_GetPosition(enemy.body_id)
	rot := b2.Body_GetRotation(enemy.body_id)
	rl.DrawRectanglePro(
		{
			pos.x - enemy.extends.x,
			pos.y - enemy.extends.y,
			enemy.extends.x * 2,
			enemy.extends.y * 2,
		},
		{0, 0},
		b2.Rot_GetAngle(rot) * rl.RAD2DEG,
		rl.RED,
	)
	rl.DrawCircleLinesV(pos.xy, 10, rl.BLACK)
}

create_enemy :: proc(world_id: b2.WorldId, pos: rl.Vector2) -> (enemy: Enemy) {
	enemy.shape_type = .ENEMY
	body := b2.DefaultBodyDef()
	body.type = .dynamicBody
	body.position = pos.xy
	body.fixedRotation = true
	body_id := b2.CreateBody(world_id, body)
	enemy.extends = {UNIT / 4, UNIT / 2}
	dynamic_box := b2.MakeBox(enemy.extends.x, enemy.extends.y)
	shape_def := b2.DefaultShapeDef()
	shape_def.density = 1
	shape_def.friction = 0.07
	shape_id := b2.CreatePolygonShape(body_id, shape_def, dynamic_box)
	enemy.body_id = body_id
	enemy.shape_id = shape_id
	enemy.jump_speed = 130 * UNIT
	enemy.move_speed = 31572 * UNIT
	enemy.move_max_velocity = 3 * UNIT
	return
}
