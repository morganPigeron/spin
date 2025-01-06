package main

import "core:c"
import "core:fmt"
import "core:log"
import "core:mem"
import "core:path/filepath"
import "core:strings"
import "core:unicode/utf8"
import b2 "vendor:box2d"
import mu "vendor:microui"
import rl "vendor:raylib"

all_windows :: proc(ctx: ^mu.Context, game_ctx: ^GameCtx) {
	@(static) opts := mu.Options{.NO_CLOSE}

	if mu.window(ctx, "Game state", {40, 40, 300, 200}, opts) {

		if .ACTIVE in mu.header(ctx, "player") {
			player := &game_ctx.player
			mu.layout_row(ctx, {150, -1}, 0)
			mu.label(ctx, "is on ground: ")
			mu.label(ctx, fmt.tprintf("%v", player.is_on_ground))
			mu.label(ctx, "position: ")
			pos := b2.Body_GetPosition(player.body_id)
			mu.label(ctx, fmt.tprintf("x: %.2f y: %.2f", pos.x, pos.y))

			{ 	// max velocity slider
				mu.label(ctx, "max velocity (m/s): ")
				value := player.move_max_velocity / UNIT
				mu.slider(ctx, &value, 0, 10)
				player.move_max_velocity = value * UNIT
			}
			{ 	// move force slider
				mu.label(ctx, "move force (N): ")
				value := player.move_speed / UNIT
				mu.slider(ctx, &value, 10000, 500000)
				player.move_speed = value * UNIT
			}
			{ 	// jump speed slider
				mu.label(ctx, "jump impulse (N): ")
				value := player.jump_speed / UNIT
				mu.slider(ctx, &value, 100, 1000)
				player.jump_speed = value * UNIT
			}
			{ 	// friction slider
				value := b2.Shape_GetFriction(player.shape_id)
				mu.label(ctx, "friction coef: ")
				mu.slider(ctx, &value, 0, 1)
				b2.Shape_SetFriction(player.shape_id, value)
			}
		}

		if .ACTIVE in mu.header(ctx, "enemy") && len(game_ctx.enemies) > 0 {
			enemy := &game_ctx.enemies[0]
			mu.layout_row(ctx, {150, -1}, 0)
			mu.label(ctx, "is on ground: ")
			mu.label(ctx, fmt.tprintf("%v", enemy.is_on_ground))
			mu.label(ctx, "position: ")
			pos := b2.Body_GetPosition(enemy.body_id)
			mu.label(ctx, fmt.tprintf("x: %.2f y: %.2f", pos.x, pos.y))
			{ 	// max velocity slider
				mu.label(ctx, "max velocity (m/s): ")
				value := enemy.move_max_velocity / UNIT
				mu.slider(ctx, &value, 0, 10)
				enemy.move_max_velocity = value * UNIT
			}
			{ 	// move force slider
				mu.label(ctx, "move force (N): ")
				value := enemy.move_speed / UNIT
				mu.slider(ctx, &value, 10000, 500000)
				enemy.move_speed = value * UNIT
			}
			{ 	// jump speed slider
				mu.label(ctx, "jump impulse (N): ")
				value := enemy.jump_speed / UNIT
				mu.slider(ctx, &value, 100, 1000)
				enemy.jump_speed = value * UNIT
			}
			{ 	// friction slider
				value := b2.Shape_GetFriction(enemy.shape_id)
				mu.label(ctx, "friction coef: ")
				mu.slider(ctx, &value, 0, 1)
				b2.Shape_SetFriction(enemy.shape_id, value)
			}
			for &e in game_ctx.enemies {
				e.move_max_velocity = enemy.move_max_velocity
				e.move_speed = enemy.move_speed
				e.jump_speed = enemy.jump_speed
				value := b2.Shape_GetFriction(enemy.shape_id)
				b2.Shape_SetFriction(e.shape_id, value)
			}
		}

		if .ACTIVE in mu.header(ctx, "wheel") {
			wheel := &game_ctx.wheel
			if .SUBMIT in mu.button(ctx, "Spin the wheel !") {
				start_wheel(wheel)
			}
			mu.layout_row(ctx, {150, -1}, 0)
			mu.label(ctx, "speed: ")
			mu.label(ctx, fmt.tprintf("%v", wheel.speed))
			mu.label(ctx, "is turning: ")
			mu.label(ctx, fmt.tprintf("%v", wheel.is_turning))
			mu.label(ctx, "need to play sound: ")
			mu.label(ctx, fmt.tprintf("%v", wheel.need_to_play_sound))
			mu.label(ctx, "is sound playing: ")
			mu.label(ctx, fmt.tprintf("%v", wheel.is_sound_playing))
			{ 	// sound volume slider
				mu.label(ctx, "volume: ")
				mu.slider(ctx, &wheel.volume_sound, 0, 1)
				rl.SetSoundVolume(wheel.bad_sound, wheel.volume_sound)
				rl.SetSoundVolume(wheel.good_sound, wheel.volume_sound)
			}
			{ 	// friction slider
				mu.label(ctx, "friction coef: ")
				mu.slider(ctx, &wheel.friction, 0, 1)
			}
			{ 	// impulse slider
				mu.label(ctx, "impulse speed: ")
				mu.slider(ctx, &wheel.impulse_speed, 20, 400)
			}
		}

		if .ACTIVE in mu.header(ctx, "camera") {
			camera := &game_ctx.camera
			mu.layout_row(ctx, {150, -1}, 0)
			mu.label(ctx, "target: ")
			mu.label(ctx, fmt.tprintf("x:%.2f y:%.2f", camera.target.x, camera.target.y))
			{ 	// friction slider
				mu.label(ctx, "zoom: ")
				mu.slider(ctx, &camera.zoom, 0.1, 10)
			}
		}

		if .ACTIVE in mu.header(ctx, "inputs") {
			inputs := &game_ctx.key_inputs
			mu.layout_row(ctx, {150, -1}, 0)
			mu.label(ctx, "functions ")
			mu.label(ctx, fmt.tprintf("keyboard key (NOT modifiable for now)"))
			for key, i in inputs {
				mu.label(ctx, fmt.tprintf("%v", i))
				mu.label(ctx, fmt.tprintf("%v", key))
			}
		}

		if .ACTIVE in mu.header(ctx, "bullets") {
			bullets := &game_ctx.bullets
			if len(bullets) > 0 {
				mu.layout_row(ctx, {150, -1}, 0)
				{ 	// speed slider 
					mu.label(ctx, "speed: ")
					mu.slider(ctx, &common_bullet.speed, 300, 10000)
				}
				{ 	// density slider
					mu.label(ctx, "density (kg) ")
					value := b2.Shape_GetDensity(bullets[0].shape_id)
					mu.slider(ctx, &value, 0, 1)
					for &b in game_ctx.bullets {
						b2.Shape_SetDensity(b.shape_id, value)
					}
				}
			}

		}
	}
}

render :: proc "contextless" (ctx: ^mu.Context) {
	render_texture :: proc "contextless" (
		renderer: rl.RenderTexture2D,
		dst: ^rl.Rectangle,
		src: mu.Rect,
		color: rl.Color,
	) {
		dst.width = f32(src.w)
		dst.height = f32(src.h)

		rl.BeginTextureMode(renderer)
		rl.DrawTextureRec(
			texture = state.atlas_texture.texture,
			source = {f32(src.x), f32(src.y), f32(src.w), f32(src.h)},
			position = {dst.x, dst.y},
			tint = color,
		)
		rl.EndTextureMode()
	}

	to_rl_color :: proc "contextless" (in_color: mu.Color) -> (out_color: rl.Color) {
		return {in_color.r, in_color.g, in_color.b, in_color.a}
	}

	rl.BeginTextureMode(state.screen_texture)
	rl.EndScissorMode()
	rl.ClearBackground(rl.Color{}) // clear background with transparent color
	rl.EndTextureMode()

	command_backing: ^mu.Command
	for variant in mu.next_command_iterator(ctx, &command_backing) {
		switch cmd in variant {
		case ^mu.Command_Text:
			dst := rl.Rectangle{f32(cmd.pos.x), f32(cmd.pos.y), 0, 0}
			for ch in cmd.str do if ch & 0xc0 != 0x80 {
				r := min(int(ch), 127)
				src := mu.default_atlas[mu.DEFAULT_ATLAS_FONT + r]
				render_texture(state.screen_texture, &dst, src, to_rl_color(cmd.color))
				dst.x += dst.width
			}
		case ^mu.Command_Rect:
			rl.BeginTextureMode(state.screen_texture)
			rl.DrawRectangle(
				cmd.rect.x,
				cmd.rect.y,
				cmd.rect.w,
				cmd.rect.h,
				to_rl_color(cmd.color),
			)
			rl.EndTextureMode()
		case ^mu.Command_Icon:
			src := mu.default_atlas[cmd.id]
			x := cmd.rect.x + (cmd.rect.w - src.w) / 2
			y := cmd.rect.y + (cmd.rect.h - src.h) / 2
			render_texture(
				state.screen_texture,
				&rl.Rectangle{f32(x), f32(y), 0, 0},
				src,
				to_rl_color(cmd.color),
			)
		case ^mu.Command_Clip:
			rl.BeginTextureMode(state.screen_texture)
			rl.BeginScissorMode(cmd.rect.x, cmd.rect.y, cmd.rect.w, cmd.rect.h)
			rl.EndTextureMode()
		case ^mu.Command_Jump:
			unreachable()
		}
	}

	//rl.BeginDrawing()
	//rl.ClearBackground(rl.RAYWHITE)
	rl.DrawTextureRec(
		texture = state.screen_texture.texture,
		source = {0, 0, f32(state.screen_width), -f32(state.screen_height)},
		position = {0, 0},
		tint = rl.WHITE,
	)
	//rl.EndDrawing()
}

u8_slider :: proc(ctx: ^mu.Context, val: ^u8, lo, hi: u8) -> (res: mu.Result_Set) {
	mu.push_id(ctx, uintptr(val))

	@(static) tmp: mu.Real
	tmp = mu.Real(val^)
	res = mu.slider(ctx, &tmp, mu.Real(lo), mu.Real(hi), 0, "%.0f", {.ALIGN_CENTER})
	val^ = u8(tmp)
	mu.pop_id(ctx)
	return
}
