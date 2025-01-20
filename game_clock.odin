package main

import "core:log"
import "core:time"
import rl "vendor:raylib"

GameClock :: struct {
	end_time:     time.Time,
	current_time: time.Time,
	time_speed:   f32,
}

new_game_clock :: proc() -> GameClock {
	endTime :: i64(30 * time.Minute + 17 * time.Hour)
	time_to_finnish :: i64(15 * time.Minute)

	return {
		current_time = time.from_nanoseconds(endTime - time_to_finnish),
		end_time = time.from_nanoseconds(endTime),
		time_speed = 1,
	}
}

update_clock :: proc(clock: ^GameClock) {
	clock.current_time = time.time_add(
		clock.current_time,
		time.Duration(f32(time.Second) * rl.GetFrameTime() * clock.time_speed),
	)
}
