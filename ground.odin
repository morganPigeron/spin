package main

import "core:fmt"
import "core:log"
import "core:mem"
import "core:strings"
import "core:unicode/utf8"

import b2 "vendor:box2d"
import mu "vendor:microui"
import rl "vendor:raylib"

Ground :: struct {
	extends :   b2.Vec2,
	body_id:    b2.BodyId,
	shape_id:   b2.ShapeId,
	shape_type: ShapeType,
}

create_ground :: proc(world_id: b2.WorldId) -> (ground: Ground) {
	ground.shape_type = .GROUND
	ground_body := b2.DefaultBodyDef()
	ground_body.position = {f32(rl.GetScreenWidth()) / 2, f32(rl.GetScreenHeight()) + UNIT / 2}
	ground_body_id := b2.CreateBody(world_id, ground_body)
	ground.extends = {f32(rl.GetScreenWidth() / 2), UNIT / 2}
	ground_box := b2.MakeBox(ground.extends.x, ground.extends.y)
	ground_shape := b2.DefaultShapeDef()
	ground_shape_id := b2.CreatePolygonShape(ground_body_id, ground_shape, ground_box)
	ground.body_id = ground_body_id
	ground.shape_id = ground_shape_id
	return
}
