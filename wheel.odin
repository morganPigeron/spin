package main

import "core:fmt"
import "core:log"
import "core:math"
import "core:mem"
import "core:strings"
import "core:time"
import "core:unicode/utf8"
import "core:math/rand"

import b2 "vendor:box2d"
import mu "vendor:microui"
import rl "vendor:raylib"

BLANC :: rl.Color{254, 250, 224, 255}

WheelElement :: struct {
    color:  rl.Color,
    sprite: Sprite,
    is_bonus: bool,
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
    winning_index:        int,
    winning_pending:      int,
}

create_wheel :: proc(ctx: GameCtx) -> (wheel: Wheel) {
    wheel.elements = make([dynamic]WheelElement, 0, 16)
    wheel.position = {175 + 20, 175 + 20}
    wheel.radius = 300
    wheel.impulse_speed = 260
    wheel.friction = 0.60

    selector := 0
    for i := 0; i < 16; i += 1 {

	sprite: Sprite
	is_bonus: bool 
	switch selector {
	case 0:
	    sprite = new_cig(ctx)
	    is_bonus = false
	case 1:
	    sprite = new_glass(ctx)
	    is_bonus = true
	case 2:
	    sprite = new_sugar(ctx)
	    is_bonus = false
	case 3:
	    sprite = new_carrot(ctx)
	    is_bonus = true
	}

	if selector == 3 {
	    selector = 0
	} else {
	    selector += 1
	}

	append(
		&wheel.elements,
	    WheelElement{color = BLANC, sprite = sprite, is_bonus = is_bonus},
	)
    }
    
    assert(len(wheel.elements) == 16)
    wheel.good_sound = ctx.musics[.GOOD_SPIN_FINAL]
    wheel.bad_sound = ctx.musics[.BAD_SPIN_FINAL]
    wheel.volume_sound = DEFAULT_VOLUME
    return
}

delete_wheel :: proc(wheel: Wheel) {
    delete(wheel.elements)
}

find_winning_index :: proc(wheel: Wheel) -> int {
    element_count := len(wheel.elements)
    angle_per_element :f32 = 360.0 / f32(element_count)
    index := int(math.ceil(wheel.angle / angle_per_element))
    if index >= 16 {
	index = 0
    }
    return index
}

update_wheel :: proc(game_ctx: GameCtx, wheel: ^Wheel) {

    //end turning
    if wheel.speed <= 0.01 && wheel.is_turning {
	wheel.speed = 0
	wheel.is_turning = false
	wheel.need_to_play_sound = true
	wheel.winning_index = find_winning_index(wheel^)
	wheel.winning_pending += 1

	if wheel.elements[wheel.winning_index].is_bonus {
	    wheel.current_playing = &wheel.good_sound 
	} else {
	    wheel.current_playing = &wheel.bad_sound
	}
    }

    if wheel.need_to_play_sound {
	wheel.need_to_play_sound = false
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
	random := rand.float32_range(-25,25)
	
	wheel.speed = wheel.impulse_speed + random
	wheel.is_turning = true
    }
}

render_wheel :: proc(ctx: GameCtx, wheel: Wheel) {
    rl.DrawCircleV(wheel.position, wheel.radius, BLANC)
    rl.DrawRing(wheel.position, wheel.radius, wheel.radius + 4, 0, 360, 60, rl.BLACK)

    winning_index := find_winning_index(wheel)
    angle: f32 = 360 / f32(len(wheel.elements))
    for &element, i in wheel.elements {
	index := i + 1
	angle_start: f32 = (angle * f32(index)) + wheel.angle
	angle_sprite: f32 = (angle * f32(index) + (angle / 2)) + wheel.angle
	angle_end: f32 = (angle * f32(index + 1)) + wheel.angle

	x_start := wheel.radius * math.sin(f32(rl.DEG2RAD) * angle_start)
	y_start := wheel.radius * math.cos(f32(rl.DEG2RAD) * angle_start)

	sprite_radius := (wheel.radius - (wheel.radius / 4))
	x_sprite := sprite_radius * math.sin(f32(rl.DEG2RAD) * angle_sprite)
	y_sprite := sprite_radius * math.cos(f32(rl.DEG2RAD) * angle_sprite)

	x_end := wheel.radius * math.sin(f32(rl.DEG2RAD) * angle_end)
	y_end := wheel.radius * math.cos(f32(rl.DEG2RAD) * angle_end)

	if i == winning_index {
	    rl.DrawTriangle(
		wheel.position,
		{x_start, y_start} + wheel.position,
		{x_end, y_end} + wheel.position,
		rl.GREEN,
	    )
	} else {
	    rl.DrawTriangle(
		wheel.position,
		{x_start, y_start} + wheel.position,
		{x_end, y_end} + wheel.position,
		element.color,
	    )
	}

	rl.DrawLineEx(wheel.position, {x_end, y_end} + wheel.position, 4, rl.BLACK)

	sprite_pos: rl.Vector2 = {x_sprite, y_sprite} +
	    (wheel.position)

	rl.DrawCircleV(sprite_pos, 30, rl.WHITE)
	render_sprite(
		&element.sprite,sprite_pos -
		{element.sprite.rect.width / 2, element.sprite.rect.height / 2}
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
	rl.DrawLineEx(wheel.position, end + wheel.position, 4, {250, 199, 72, 255})
    }

    { 	// min
	angle: f32 = (f32(m) * 360 / 60) - 90
	end := polar_to_cartesian(wheel.radius / 4 * 3, f32(rl.DEG2RAD) * angle)
	rl.DrawLineEx(wheel.position, end + wheel.position, 6, {131, 144, 250, 255})
    }

    { 	// hour
	angle: f32 = (f32(h) * 360 / 12) - 90
	end := polar_to_cartesian(wheel.radius / 2, f32(rl.DEG2RAD) * angle)
	rl.DrawLineEx(wheel.position, end + wheel.position, 8, {29, 47, 111, 255})
    }

    {   //pivot
	rl.DrawCircleV(wheel.position, 10, {29, 47, 111, 255})
    }

}
