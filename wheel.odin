package main

import "core:fmt"
import "core:log"
import "core:math"
import "core:mem"
import "core:strings"
import "core:time"
import "core:unicode/utf8"

import b2 "vendor:box2d"
import mu "vendor:microui"
import rl "vendor:raylib"

WheelElement :: struct {
    color:  rl.Color,
    sprite: Sprite,
}

Wheel :: struct {
    position:             rl.Vector2,
    radius:               f32,
    elements:             [dynamic]WheelElement,
    angle:                f32,
    speed:                f32,
    impulse_speed:        f32,
    friction:             f32,
    is_turning:           bool,
    need_to_play_sound:   bool,
    is_sound_playing:     bool,
    good_sound:           rl.Music,
    bad_sound:            rl.Music,
    current_playing:      ^rl.Music,
    current_playing_time: f32,
    volume_sound:         f32,
    sound_play_offset:    f32,
}

create_wheel :: proc(ctx: GameCtx) -> (wheel: Wheel) {
    wheel.elements = make([dynamic]WheelElement, 0, 16)
    wheel.position = {175 + 20, 175 + 20}
    wheel.radius = 300
    wheel.impulse_speed = 260
    wheel.friction = 0.60

    selector := 0
    for i in 0 ..< 16 {

	sprite: Sprite
	switch selector {
	case 0:
	    sprite = new_cig(ctx)
	case 1:
	    sprite = new_glass(ctx)
	case 2:
	    sprite = new_sugar(ctx)
	case 3:
	    sprite = new_carrot(ctx)
	}

	if selector == 3 {
	    selector = 0
	} else {
	    selector += 1
	}

	append(
		&wheel.elements,
	    WheelElement{color = rl.Color{u8(i * 40), 125, u8(i * 20), 255}, sprite = sprite},
	)
    }
    wheel.good_sound = ctx.musics[.GOOD_SPIN_FINAL]
    wheel.bad_sound = ctx.musics[.BAD_SPIN_FINAL]
    wheel.volume_sound = DEFAULT_VOLUME
    return
}

delete_wheel :: proc(wheel: Wheel) {
    delete(wheel.elements)
}

update_wheel :: proc(game_ctx: GameCtx, wheel: ^Wheel) {

    if wheel.speed <= 0.01 && wheel.is_turning {
	wheel.speed = 0
	wheel.is_turning = false
	wheel.need_to_play_sound = true
    }

    if wheel.need_to_play_sound {
	wheel.need_to_play_sound = false
	wheel.current_playing = &wheel.bad_sound
	wheel.current_playing_time = 0
	rl.SetMusicVolume(wheel.current_playing^, wheel.volume_sound)
	rl.SeekMusicStream(
	    wheel.current_playing^,
	    game_ctx.main_music_delta_from_beat + wheel.sound_play_offset,
	)
	rl.PlayMusicStream(wheel.current_playing^)
    }

    if wheel.is_turning {
	wheel.speed -= wheel.friction
	wheel.angle += wheel.speed * rl.GetFrameTime()
	if wheel.angle >= 360 {
	    wheel.angle = 0
	}
    }

    if wheel.current_playing != nil {
	wheel.is_sound_playing = rl.IsMusicStreamPlaying(wheel.current_playing^)
    }

    if (wheel.is_sound_playing) {
	rl.UpdateMusicStream(wheel.current_playing^)
	wheel.current_playing_time += rl.GetFrameTime()
	length := rl.GetMusicTimeLength(wheel.current_playing^)
	if wheel.current_playing_time >= length + wheel.sound_play_offset {
	    wheel.current_playing_time = 0
	    rl.StopMusicStream(wheel.current_playing^)
	    rl.SeekMusicStream(wheel.current_playing^, 0)
	}
    }

    for &e in wheel.elements {
	update_sprite(&e.sprite)
    }
}

start_wheel :: proc(wheel: ^Wheel) {
    if wheel.is_turning == false {
	wheel.speed = wheel.impulse_speed
	wheel.is_turning = true
    }
}

render_wheel :: proc(ctx: GameCtx, wheel: Wheel) {
    rl.DrawCircleV(wheel.position, wheel.radius, rl.PURPLE)

    angle: f32 = 360 / f32(len(wheel.elements))
    for &element, i in wheel.elements {
	angle_start: f32 = (angle * f32(i)) + wheel.angle
	angle_sprite: f32 = (angle * f32(i) + (angle / 2)) + wheel.angle
	angle_end: f32 = (angle * f32(i + 1)) + wheel.angle

	x_start := wheel.radius * math.sin(f32(rl.DEG2RAD) * angle_start)
	y_start := wheel.radius * math.cos(f32(rl.DEG2RAD) * angle_start)

	sprite_radius := (wheel.radius - (wheel.radius / 4))
	x_sprite := sprite_radius * math.sin(f32(rl.DEG2RAD) * angle_sprite)
	y_sprite := sprite_radius * math.cos(f32(rl.DEG2RAD) * angle_sprite)

	x_end := wheel.radius * math.sin(f32(rl.DEG2RAD) * angle_end)
	y_end := wheel.radius * math.cos(f32(rl.DEG2RAD) * angle_end)

	rl.DrawTriangle(
	    wheel.position,
	    {x_start, y_start} + wheel.position,
	    {x_end, y_end} + wheel.position,
	    element.color,
	)
	render_sprite(
		&element.sprite,
	    {x_sprite, y_sprite} +
		(wheel.position - {element.sprite.rect.width / 2, element.sprite.rect.height / 2}),
	)
    }

    // draw clock
    clock := ctx.game_clock
    h, m, s := time.clock_from_time(clock.current_time)

    { 	// numeric clock
	rl.DrawRectangle(
	    i32(wheel.position.x - 29 - 5),
	    i32(wheel.position.y + 20),
	    78,
	    20,
	    rl.DARKGRAY,
	)
	rl.DrawText(
	    fmt.ctprintf("%v:%v:%2d", h, m, s),
	    i32(wheel.position.x - 29),
	    i32(wheel.position.y + 20),
	    20,
	    {255, 191, 0, 255},
	)
    }

    { 	// sec
	angle: f32 = (f32(s) * 360 / 60) - 90
	end := polar_to_cartesian(wheel.radius, f32(rl.DEG2RAD) * angle)
	rl.DrawLineEx(wheel.position, end + wheel.position, 1, rl.BLACK)
    }

    { 	// min
	angle: f32 = (f32(m) * 360 / 60) - 90
	end := polar_to_cartesian(wheel.radius / 4 * 3, f32(rl.DEG2RAD) * angle)
	rl.DrawLineEx(wheel.position, end + wheel.position, 2, rl.BLACK)
    }

    { 	// hour
	angle: f32 = (f32(h) * 360 / 12) - 90
	end := polar_to_cartesian(wheel.radius / 2, f32(rl.DEG2RAD) * angle)
	rl.DrawLineEx(wheel.position, end + wheel.position, 3, rl.BLACK)
    }

}
