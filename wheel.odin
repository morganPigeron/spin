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
	position: rl.Vector2,
	radius:   f32,
	elements: [dynamic]WheelElement,
}

create_wheel :: proc() -> (wheel: Wheel) {
	wheel.elements = make([dynamic]WheelElement, 0, 16)
	wheel.position = {175 + 20, 175 + 20}
	wheel.radius = 175

	for i in 0 ..< 16 {
		append(&wheel.elements, WheelElement{color = rl.Color{u8(i * 10), 125, u8(i * 10), 255}})
	}

	return
}

delete_wheel :: proc(wheel: Wheel) {
	delete(wheel.elements)
}

update_wheel :: proc(wheel: ^Wheel) {

}

render_wheel :: proc(wheel: ^Wheel) {
	rl.DrawCircleV(wheel.position, wheel.radius, rl.PURPLE)

	angle: f32 = 360 / f32(len(wheel.elements))
	for element, i in wheel.elements {
		angle_start: f32 = (angle * f32(i))
		angle_end: f32 = (angle * f32(i + 1))

		x_start := wheel.radius * math.sin(f32(rl.DEG2RAD) * angle_start)
		y_start := wheel.radius * math.cos(f32(rl.DEG2RAD) * angle_start)

		x_end := wheel.radius * math.sin(f32(rl.DEG2RAD) * angle_end)
		y_end := wheel.radius * math.cos(f32(rl.DEG2RAD) * angle_end)

		rl.DrawTriangleLines(
			wheel.position,
			{x_start, y_start} + wheel.position,
			{x_end, y_end} + wheel.position,
			rl.RED,
		)
	}
}
