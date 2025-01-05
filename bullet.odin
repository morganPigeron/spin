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

create_bullet_from_player :: proc(world_id: b2.WorldId) -> (bullet: Bullet) {
	bullet.shape_type = .BULLET_FROM_PLAYER
	body := b2.DefaultBodyDef()
	body.type = .dynamicBody
	body.fixedRotation = true
	body.position = {UNIT / 4, UNIT / 4}
	body_id := b2.CreateBody(world_id, body)
	bullet.extends = {UNIT / 4, UNIT / 2}
	dynamic_box := b2.MakeBox(bullet.extends.x, bullet.extends.y)
	shape_def := b2.DefaultShapeDef()
	shape_def.density = 1
	shape_id := b2.CreatePolygonShape(body_id, shape_def, dynamic_box)
	bullet.body_id = body_id
	bullet.shape_id = shape_id
	return
}
