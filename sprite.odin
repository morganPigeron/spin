package main

import rl "vendor:raylib"

Sprite :: struct {
	texture:      rl.Texture,
	rect:         rl.Rectangle,
	frame_count:  int,
	frame_cursor: int,
	increment:    int,
	current_time: f32,
	frame_time:   f32,
	ping_pong:    bool,
}

new_cig :: proc() -> (result: Sprite) {
	result.texture = rl.LoadTexture(CIG)
	result.rect = rl.Rectangle{0, 0, 32, 32}
	result.frame_count = 11
	result.frame_cursor = 0
	result.current_time = 0.0
	result.frame_time = 0.12
	result.increment = 1
	return
}

new_glass :: proc() -> (result: Sprite) {
	result.texture = rl.LoadTexture(GLASSES)
	result.rect = rl.Rectangle{0, 0, 32, 32}
	result.frame_count = 10
	result.frame_cursor = 0
	result.current_time = 0.0
	result.frame_time = 0.12
	result.increment = 1
	result.ping_pong = true
	return
}

new_sugar :: proc() -> (result: Sprite) {
	result.texture = rl.LoadTexture(SUGAR)
	result.rect = rl.Rectangle{0, 0, 32, 32}
	result.frame_count = 9
	result.frame_cursor = 0
	result.current_time = 0.0
	result.frame_time = 0.12
	result.increment = 1
	result.ping_pong = true
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

render_sprite :: proc(s: Sprite, pos: rl.Vector2) {
	rl.DrawTextureRec(s.texture, s.rect, pos, rl.WHITE)
}
