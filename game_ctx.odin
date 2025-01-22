#+feature dynamic-literals

package main

import "core:log"
import "core:slice"
import "core:time"
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
	PlaceSprite,
	Remove,
}

GameCtx :: struct {
	current_scene:          Scenes,
	world_id:               b2.WorldId,
	camera:                 rl.Camera2D,
	player:                 Player,
	wheel:                  Wheel,
	grounds:                [dynamic]Ground,
	images:                 [dynamic]Image,
	sprites:                [dynamic]Sprite,
	enemies:                [dynamic]Enemy,
	bullets:                [dynamic]Bullet,
	key_inputs:             [InputList]rl.KeyboardKey,
	is_editor:              bool,
	editor_mode:            EditorMode,
	editor_selected_sprite: Sprite,
	assets:                 map[Assets]rl.Texture2D,
	musics:                 map[Sounds]rl.Music,
	selected_asset:         Assets,
	game_clock:             GameClock,
}

spawn_player_bullet :: proc(ctx: ^GameCtx, start_pos: rl.Vector2, direction: rl.Vector2) {
	append(&ctx.bullets, create_bullet_from_player(ctx^, ctx.world_id))
	bullet := &ctx.bullets[len(ctx.bullets) - 1]
	bullet.direction = direction
	b2.Body_SetTransform(bullet.body_id, start_pos, {0, 0})
	b2.Body_ApplyLinearImpulseToCenter(bullet.body_id, bullet.speed * bullet.direction, true)
}

new_game_ctx :: proc() -> (ctx: GameCtx) {
	ctx.enemies = make([dynamic]Enemy, 0, 100)
	ctx.bullets = make([dynamic]Bullet, 0, 100)
	ctx.sprites = make([dynamic]Sprite, 0, 100)
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

	load_textures()
	defer delete_textures()
	ctx.assets = {
		.GLASSES   = AssetsList[.GLASSES],
		.CIG       = AssetsList[.CIG],
		.SUGAR     = AssetsList[.SUGAR],
		.PLANT     = AssetsList[.PLANT],
		.CUBICLE   = AssetsList[.CUBICLE],
		.CHARACTER = AssetsList[.CHARACTER],
		.PRINTER   = AssetsList[.PRINTER],
		.BOY1      = AssetsList[.BOY1],
		.GIRL1     = AssetsList[.GIRL1],
		.GIRL2     = AssetsList[.GIRL2],
		.STAPPLER  = AssetsList[.STAPPLER],
		.CARROT    = AssetsList[.CARROT],
	}
	assert(len(ctx.assets) == len(AssetsList))

	ctx.musics = {
		.BAD_SPIN     = SoundsList[.BAD_SPIN],
		.BAD_SPIN_2   = SoundsList[.BAD_SPIN_2],
		.GOOD_SPIN    = SoundsList[.GOOD_SPIN],
		.GOOD_SPIN_2  = SoundsList[.GOOD_SPIN_2],
		.MAIN_THEME   = SoundsList[.MAIN_THEME],
		.MAIN_THEME_2 = SoundsList[.MAIN_THEME_2],
		.ATTACK_FX_1  = SoundsList[.ATTACK_FX_1],
		.ATTACK_FX_2  = SoundsList[.ATTACK_FX_2],
		.ATTACK_FX_3  = SoundsList[.ATTACK_FX_3],
		.JUMP_FX_1    = SoundsList[.JUMP_FX_1],
		.JUMP_FX_2    = SoundsList[.JUMP_FX_2],
		.JUMP_FX_3    = SoundsList[.JUMP_FX_3],
		.WALKING_FX_1 = SoundsList[.WALKING_FX_1],
		.WALKING_FX_2 = SoundsList[.WALKING_FX_2],
		.WALKING_FX_3 = SoundsList[.WALKING_FX_3],
	}
	assert(len(ctx.musics) == len(SoundsList))

	ctx.game_clock = new_game_clock()
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
	delete(ctx.sprites)
	delete(ctx.images)
	delete(ctx.musics)
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
	V2, // sprites added as background
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

	case .V2:
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

		sprite_count := eat_next(buffer, &cursor, int)
		for i := 0; i < sprite_count; i += 1 {
			pos := eat_next(buffer, &cursor, rl.Vector2)
			asset := eat_next(buffer, &cursor, Assets)
			rect := eat_next(buffer, &cursor, rl.Rectangle)
			append(&ctx.sprites, create_sprite(ctx^, pos, asset))
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

serialize_ctx_v2 :: proc(ctx: ^GameCtx) -> []u8 {
	result: [dynamic]u8

	serialize_type(&result, SerializeVersion.V2)

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

	serialize_type(&result, len(ctx.sprites))
	for sprite in ctx.sprites {
		serialize_type(&result, sprite.position)
		serialize_type(&result, sprite.asset)
		serialize_type(&result, sprite.rect)
	}

	return result[:]
}
