package main

import rl "vendor:raylib"

Sprite :: struct {
	position:     rl.Vector2,
	texture:      rl.Texture,
	asset:        Assets,
	rect:         rl.Rectangle,
	frame_count:  int,
	frame_cursor: int,
	increment:    int,
	current_time: f32,
	frame_time:   f32,
	ping_pong:    bool,
}

create_sprite :: proc(ctx: GameCtx, pos: rl.Vector2, asset: Assets) -> Sprite {
	#partial switch asset {
	case .PRINTER:
		result := new_printer(ctx)
		result.position = pos
		return result
	}
	return new_printer(ctx)
}

new_cig :: proc(ctx: GameCtx) -> (result: Sprite) {
	result.texture = ctx.assets[.CIG]
	result.asset = .CIG
	result.rect = rl.Rectangle{0, 0, 32, 32}
	result.frame_count = 11
	result.frame_cursor = 0
	result.current_time = 0.0
	result.frame_time = 0.12
	result.increment = 1
	return
}

new_glass :: proc(ctx: GameCtx) -> (result: Sprite) {
	result.texture = ctx.assets[.GLASSES]
	result.asset = .GLASSES
	result.rect = rl.Rectangle{0, 0, 32, 32}
	result.frame_count = 10
	result.frame_cursor = 0
	result.current_time = 0.0
	result.frame_time = 0.12
	result.increment = 1
	result.ping_pong = true
	return
}

new_sugar :: proc(ctx: GameCtx) -> (result: Sprite) {
	result.texture = ctx.assets[.SUGAR]
	result.asset = .SUGAR
	result.rect = rl.Rectangle{0, 0, 32, 32}
	result.frame_count = 9
	result.frame_cursor = 0
	result.current_time = 0.0
	result.frame_time = 0.12
	result.increment = 1
	result.ping_pong = true
	return
}

new_printer :: proc(ctx: GameCtx) -> (result: Sprite) {
	result.texture = ctx.assets[.PRINTER]
	result.asset = .PRINTER
	result.rect = rl.Rectangle{0, 0, 48, 48}
	result.frame_count = 16
	result.frame_cursor = 0
	result.current_time = 0.0
	result.frame_time = 0.12
	result.increment = 1
	result.ping_pong = false
	return
}

update_sprite :: proc(s: ^Sprite) {
	s.current_time += rl.GetFrameTime()
	if s.current_time > s.frame_time {
		s.current_time = 0

		if s.ping_pong {
			if s.frame_cursor >= s.frame_count * 2 {
				s.frame_cursor = 0
			}
			if s.frame_cursor == s.frame_count - 1 {
				s.increment = -1
			} else if s.frame_cursor == 0 {
				s.increment = 1
			}
		} else {
			if s.frame_cursor >= s.frame_count {
				s.frame_cursor = 0
			}
		}

		s.frame_cursor += s.increment

		s.rect.x = s.rect.width * f32(s.frame_cursor)
	}
}

render_sprite :: proc(s: ^Sprite, pos: rl.Vector2) {
	s.position = pos
	rl.DrawTextureRec(s.texture, s.rect, s.position, rl.WHITE)
}
