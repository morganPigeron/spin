package main

import "core:fmt"
import "core:log"
import "core:mem"
import "core:strings"
import "core:unicode/utf8"

import b2 "vendor:box2d"
import rl "vendor:raylib"

Bullet :: struct {
	body_id:    b2.BodyId,
	shape_id:   b2.ShapeId,
	extends:    b2.Vec2,
	shape_type: ShapeType,
	speed:      f32,
	direction:  rl.Vector2,
}

common_bullet: Bullet = {
	speed = 3000,
}

create_bullet_from_player :: proc(world_id: b2.WorldId) -> (bullet: Bullet) {
	bullet.shape_type = .BULLET_FROM_PLAYER
	body := b2.DefaultBodyDef()
	body.type = .dynamicBody
	body.position = {0, 0}
	body.fixedRotation = true
	body_id := b2.CreateBody(world_id, body)
	bullet.extends = {UNIT / 10, UNIT / 10}
	dynamic_box := b2.MakeBox(bullet.extends.x, bullet.extends.y)
	shape_def := b2.DefaultShapeDef()
	shape_def.enableHitEvents = true
	shape_def.density = 1
	shape_id := b2.CreatePolygonShape(body_id, shape_def, dynamic_box)
	bullet.body_id = body_id
	bullet.shape_id = shape_id
	bullet.speed = common_bullet.speed * UNIT
	b2.Shape_SetUserData(shape_id, &ShapeTypeBulletFromPlayer)
	return
}

render_bullet :: proc(bullet: Bullet) {
	pos := b2.Body_GetPosition(bullet.body_id)
	rl.DrawCircleV(pos.xy, bullet.extends.x, rl.PURPLE)
}
