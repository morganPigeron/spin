package main

import "core:fmt"
import "core:log"
import "core:math"
import "core:mem"
import "core:strings"
import "core:unicode/utf8"

import b2 "vendor:box2d"
import mu "vendor:microui"
import rl "vendor:raylib"

WheelElement :: struct {
	color: rl.Color,
}

Wheel :: struct {
	position:           rl.Vector2,
	radius:             f32,
	elements:           [dynamic]WheelElement,
	angle:              f32,
	speed:              f32,
	impulse_speed:      f32,
	friction:           f32,
	is_turning:         bool,
	need_to_play_sound: bool,
	is_sound_playing:   bool,
	good_sound:         rl.Sound,
	bad_sound:          rl.Sound,
	volume_sound:       f32,
}

create_wheel :: proc() -> (wheel: Wheel) {
	wheel.elements = make([dynamic]WheelElement, 0, 16)
	wheel.position = {175 + 20, 175 + 20}
	wheel.radius = 175
	wheel.impulse_speed = 260
	wheel.friction = 0.60
	for i in 0 ..< 16 {
		append(&wheel.elements, WheelElement{color = rl.Color{u8(i * 40), 125, u8(i * 20), 255}})
	}

	wheel.good_sound = rl.LoadSound(GOOD_SPIN)
	wheel.bad_sound = rl.LoadSound(BAD_SPIN)
	wheel.volume_sound = 1
	return
}

delete_wheel :: proc(wheel: Wheel) {
	delete(wheel.elements)
}

update_wheel :: proc(wheel: ^Wheel) {

	if wheel.speed <= 0.01 && wheel.is_turning {
		wheel.speed = 0
		wheel.is_turning = false
		wheel.need_to_play_sound = true
	}

	if wheel.need_to_play_sound {
		wheel.need_to_play_sound = false
		rl.SetSoundVolume(wheel.good_sound, wheel.volume_sound)
		rl.PlaySound(wheel.good_sound)
	}

	if wheel.is_turning {
		wheel.speed -= wheel.friction
		wheel.angle += wheel.speed * rl.GetFrameTime()
		if wheel.angle >= 360 {
			wheel.angle = 0
		}
	}

	wheel.is_sound_playing = rl.IsSoundPlaying(wheel.good_sound)
}

start_wheel :: proc(wheel: ^Wheel) {
	if wheel.is_turning == false {
		wheel.speed = wheel.impulse_speed
		wheel.is_turning = true
	}
}
render_wheel :: proc(wheel: Wheel) {
	rl.DrawCircleV(wheel.position, wheel.radius, rl.PURPLE)

	angle: f32 = 360 / f32(len(wheel.elements))
	for element, i in wheel.elements {
		angle_start: f32 = (angle * f32(i)) + wheel.angle
		angle_end: f32 = (angle * f32(i + 1)) + wheel.angle

		x_start := wheel.radius * math.sin(f32(rl.DEG2RAD) * angle_start)
		y_start := wheel.radius * math.cos(f32(rl.DEG2RAD) * angle_start)

		x_end := wheel.radius * math.sin(f32(rl.DEG2RAD) * angle_end)
		y_end := wheel.radius * math.cos(f32(rl.DEG2RAD) * angle_end)

		rl.DrawTriangle(
			wheel.position,
			{x_start, y_start} + wheel.position,
			{x_end, y_end} + wheel.position,
			element.color,
		)
	}
}
