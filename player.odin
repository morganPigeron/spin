package main

import "core:fmt"
import "core:log"
import "core:mem"
import "core:strings"
import "core:unicode/utf8"

import b2 "vendor:box2d"
import rl "vendor:raylib"

Player :: struct {
	body_id:           b2.BodyId,
	shape_id:          b2.ShapeId,
	extends:           b2.Vec2,
	shape_type:        ShapeType,
	jump_speed:        f32,
	move_speed:        f32,
	move_max_velocity: f32,
	is_on_ground:      bool,
	image:             Image,
}

player_shoot :: proc(ctx: ^GameCtx) {
	direction: rl.Vector2 = {0, 0}
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

player_move_right :: proc(player: ^Player) {
	velocity := b2.Body_GetLinearVelocity(player.body_id).x
	if velocity < 0 || abs(velocity) < player.move_max_velocity {
		b2.Body_ApplyForceToCenter(player.body_id, {player.move_speed, 0}, true)
	}
}

player_move_left :: proc(player: ^Player) {
	velocity := b2.Body_GetLinearVelocity(player.body_id).x
	if velocity > 0 || abs(velocity) < player.move_max_velocity {
		b2.Body_ApplyForceToCenter(player.body_id, {-player.move_speed, 0}, true)
	}
}

player_jump :: proc(player: ^Player) {
	if player.is_on_ground {
		b2.Body_ApplyLinearImpulseToCenter(player.body_id, {0, -UNIT * player.jump_speed}, true)
	}
}

update_player :: proc(player: ^Player, contact_events: b2.ContactEvents) {
	for begin in contact_events.beginEvents[:contact_events.beginCount] {
		a := transmute(^ShapeType)b2.Shape_GetUserData(begin.shapeIdA)
		b := transmute(^ShapeType)b2.Shape_GetUserData(begin.shapeIdB)

		if a^ == .GROUND && b^ == .PLAYER {
			player.is_on_ground = true
		} else if a^ == .PLAYER && b^ == .GROUND {
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

	pos := b2.Body_GetPosition(player.body_id)
	player.image.pos =
		pos - ({f32(player.image.texture.width), f32(player.image.texture.height)} / 2)
}

render_player :: proc(player: Player) {
	pos := b2.Body_GetPosition(player.body_id)
	rot := b2.Body_GetRotation(player.body_id)
	/*
	rl.DrawRectanglePro(
		{
			pos.x - player.extends.x,
			pos.y - player.extends.y,
			player.extends.x * 2,
			player.extends.y * 2,
		},
		{0, 0},
		b2.Rot_GetAngle(rot) * rl.RAD2DEG,
		rl.BLUE,
	)
	*/
	render_image(player.image)
	rl.DrawCircleLinesV(pos.xy, 10, rl.BLACK)
}

create_player :: proc(ctx: GameCtx) -> (player: Player) {
	player.shape_type = .PLAYER
	body := b2.DefaultBodyDef()
	body.type = .dynamicBody
	body.position = {f32(rl.GetScreenWidth()) / 2, -4}
	body.fixedRotation = true
	body_id := b2.CreateBody(ctx.world_id, body)
	player.extends = {UNIT / 4, UNIT / 2}
	dynamic_box := b2.MakeBox(player.extends.x, player.extends.y)
	shape_def := b2.DefaultShapeDef()
	shape_def.density = 1
	shape_def.friction = 0.07
	shape_def.enableHitEvents = true
	shape_id := b2.CreatePolygonShape(body_id, shape_def, dynamic_box)
	player.body_id = body_id
	player.shape_id = shape_id
	player.jump_speed = 130 * UNIT
	player.move_speed = 31572 * UNIT
	player.move_max_velocity = 3 * UNIT
	b2.Shape_SetUserData(shape_id, &ShapeTypePlayer)
	player.image = create_image(ctx, body.position, .CHARACTER)
	return
}
