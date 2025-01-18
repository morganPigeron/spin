#+feature dynamic-literals

package main

import "core:slice"
import b2 "vendor:box2d"
import rl "vendor:raylib"

InputList :: enum {
	UP,
	DOWN,
	LEFT,
	RIGHT,
	JUMP,
	SHOOT,
	TOGGLE_EDITOR,
}

Scenes :: enum {
	Menu,
	Test,
}

EditorMode :: enum {
	None,
	PlaceGround,
	PlaceImage,
	Remove,
}

GameCtx :: struct {
	current_scene:  Scenes,
	world_id:       b2.WorldId,
	camera:         rl.Camera2D,
	player:         Player,
	wheel:          Wheel,
	grounds:        [dynamic]Ground,
	images:         [dynamic]Image,
	enemies:        [dynamic]Enemy,
	bullets:        [dynamic]Bullet,
	key_inputs:     [InputList]rl.KeyboardKey,
	main_track:     Track,
	is_editor:      bool,
	editor_mode:    EditorMode,
	assets:         map[Assets]rl.Texture2D,
	selected_asset: Assets,
}

spawn_player_bullet :: proc(ctx: ^GameCtx, start_pos: rl.Vector2, direction: rl.Vector2) {
	append(&ctx.bullets, create_bullet_from_player(ctx.world_id))
	bullet := &ctx.bullets[len(ctx.bullets) - 1]
	bullet.direction = direction
	b2.Body_SetTransform(bullet.body_id, start_pos, {0, 0})
	b2.Body_ApplyLinearImpulseToCenter(bullet.body_id, bullet.speed * bullet.direction, true)
}

new_game_ctx :: proc() -> (ctx: GameCtx) {
	ctx.enemies = make([dynamic]Enemy, 0, 100)
	ctx.bullets = make([dynamic]Bullet, 0, 100)
	ctx.grounds = make([dynamic]Ground, 0, 100)
	ctx.images = make([dynamic]Image, 0, 100)
	ctx.key_inputs = {
		.UP            = .W,
		.DOWN          = .S,
		.LEFT          = .A,
		.RIGHT         = .D,
		.JUMP          = .SPACE,
		.SHOOT         = .LEFT_CONTROL,
		.TOGGLE_EDITOR = .E,
	}
	ctx.current_scene = .Menu
	ctx.main_track = load_main_track()

	ctx.assets = {
		.PLANT     = rl.LoadTexture(PLANT),
		.GLASSES   = rl.LoadTexture(GLASSES),
		.CIG       = rl.LoadTexture(CIG),
		.SUGAR     = rl.LoadTexture(SUGAR),
		.CUBICLE   = rl.LoadTexture(CUBICLE),
		.CHARACTER = rl.LoadTexture(CHARACTER),
		.PRINTER   = rl.LoadTexture(PRINTER),
		.BOY1      = rl.LoadTexture(BOY1),
		.GIRL1     = rl.LoadTexture(GIRL1),
		.GIRL2     = rl.LoadTexture(GIRL2),
	}
	return
}

delete_game_ctx :: proc(ctx: GameCtx) {

	// TODO cleanup box2D physic
	//b2.DestroyWorld(ctx.world_id)
	for e in ctx.enemies {
		cleanup_enemy(e)
	}
	delete(ctx.enemies)
	delete(ctx.bullets)
	delete(ctx.grounds)
	delete(ctx.assets)
	delete(ctx.images)
	delete_wheel(ctx.wheel)
}

change_scene :: proc(ctx: ^GameCtx, new_scene: Scenes) {
	switch new_scene {
	case .Menu:
	case .Test:
		setup_test_scene(ctx)
		ctx.current_scene = .Test
	}
}

SerializeVersion :: enum {
	V1,
}

eat_next :: proc(buffer: []u8, cursor: ^int, $T: typeid) -> T {
	result := slice.to_type(buffer[cursor^:cursor^ + size_of(T)], T)
	cursor^ += size_of(T)
	return result
}

serialize_type :: proc(buffer: ^[dynamic]u8, V: $T) {
	x := transmute([size_of(T)]u8)V
	append(buffer, ..x[:])
}

deserialize_ctx :: proc(ctx: ^GameCtx, buffer: []u8) {

	//cleanup 
	for ground in ctx.grounds {
		delete_ground(ground)
	}
	clear(&ctx.grounds)
	clear(&ctx.images)

	cursor: int = 0
	version := eat_next(buffer, &cursor, SerializeVersion)

	switch version {
	case .V1:
		ground_count := eat_next(buffer, &cursor, int)
		for i := 0; i < ground_count; i += 1 {
			pos := eat_next(buffer, &cursor, b2.Vec2)
			extend := eat_next(buffer, &cursor, b2.Vec2) // TODO no need for now 
			shape_type := eat_next(buffer, &cursor, ShapeType) // TODO no need for now 
			append(&ctx.grounds, create_ground(ctx.world_id, pos))
		}

		image_count := eat_next(buffer, &cursor, int)
		for i := 0; i < image_count; i += 1 {
			pos := eat_next(buffer, &cursor, rl.Vector2)
			asset := eat_next(buffer, &cursor, Assets)
			append(&ctx.images, create_image(ctx^, pos, asset))
		}
	}

}

serialize_ctx_v1 :: proc(ctx: ^GameCtx) -> []u8 {
	result: [dynamic]u8

	serialize_type(&result, SerializeVersion.V1)

	serialize_type(&result, len(ctx.grounds))
	for ground in ctx.grounds {
		serialize_type(&result, b2.Body_GetPosition(ground.body_id))
		serialize_type(&result, ground.extends)
		serialize_type(&result, ground.shape_type)
	}

	serialize_type(&result, len(ctx.images))
	for image in ctx.images {
		serialize_type(&result, image.pos)
		serialize_type(&result, image.asset)
	}

	return result[:]
}
