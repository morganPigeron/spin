package main

import "core:fmt"
import "core:log"
import "core:mem"
import "core:strings"
import "core:unicode/utf8"

import b2 "vendor:box2d"
import rl "vendor:raylib"

Bullet :: struct {
	sprite:           Sprite,
	body_id:          b2.BodyId,
	shape_id:         b2.ShapeId,
	extends:          b2.Vec2,
	shape_type:       ShapeType,
	speed:            f32,
	direction:        rl.Vector2,
	density:          f32,
	time_to_live_sec: f32,
}

common_bullet: Bullet = {
	speed            = 144,
	density          = 0.1,
	time_to_live_sec = 2,
}

create_bullet_from_player :: proc(ctx: GameCtx, world_id: b2.WorldId) -> (bullet: Bullet) {
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
	shape_def.density = common_bullet.density
	shape_id := b2.CreatePolygonShape(body_id, shape_def, dynamic_box)
	bullet.body_id = body_id
	bullet.shape_id = shape_id
	bullet.speed = common_bullet.speed * UNIT
	bullet.time_to_live_sec = common_bullet.time_to_live_sec
	bullet.sprite = new_stappler(ctx)
	b2.Shape_SetUserData(shape_id, &ShapeTypeBulletFromPlayer)
	return
}

cleanup_bullet :: proc(bullet: Bullet) {
	b2.DestroyBody(bullet.body_id)
}

update_bullet :: proc(bullet: ^Bullet) {
	bullet.time_to_live_sec -= rl.GetFrameTime()
	update_sprite(&bullet.sprite)
}

render_bullet :: proc(bullet: ^Bullet) {
	pos := b2.Body_GetPosition(bullet.body_id)
	render_sprite(&bullet.sprite, pos)
	//rl.DrawCircleV(pos.xy, bullet.extends.x, rl.PURPLE)
}
