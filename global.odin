package main

import "core:c"
import "core:fmt"
import "core:log"
import "core:mem"
import "core:strings"
import "core:unicode/utf8"
import mu "vendor:microui"
import rl "vendor:raylib"

// microui binding
state := struct {
    mu_ctx:         mu.Context,
    bg:             mu.Color,
    atlas_texture:  rl.RenderTexture2D,
    screen_width:   c.int,
    screen_height:  c.int,
    screen_texture: rl.RenderTexture2D,
} {
    screen_width  = INITIAL_SCREEN_WIDTH,
    screen_height = INITIAL_SCREEN_HEIGHT,
    bg            = {90, 95, 100, 255},
}

mouse_buttons_map := [mu.Mouse]rl.MouseButton {
	.LEFT   = .LEFT,
	.RIGHT  = .RIGHT,
	.MIDDLE = .MIDDLE,
}

key_map := [mu.Key][2]rl.KeyboardKey {
	.SHIFT     = {.LEFT_SHIFT, .RIGHT_SHIFT},
	.CTRL      = {.LEFT_CONTROL, .RIGHT_CONTROL},
	.ALT       = {.LEFT_ALT, .RIGHT_ALT},
	.BACKSPACE = {.BACKSPACE, .KEY_NULL},
	.DELETE    = {.DELETE, .KEY_NULL},
	.RETURN    = {.ENTER, .KP_ENTER},
	.LEFT      = {.LEFT, .KEY_NULL},
	.RIGHT     = {.RIGHT, .KEY_NULL},
	.HOME      = {.HOME, .KEY_NULL},
	.END       = {.END, .KEY_NULL},
	.A         = {.A, .KEY_NULL},
	.X         = {.X, .KEY_NULL},
	.C         = {.C, .KEY_NULL},
	.V         = {.V, .KEY_NULL},
}

ShapeType :: enum {
    PLAYER,
    GROUND,
    ENEMY,
    BOSS,
    BULLET_FROM_PLAYER,
    BULLET_FROM_BOSS,
}

ShapeTypeGround := ShapeType.GROUND
ShapeTypePlayer := ShapeType.PLAYER
ShapeTypeEnemy := ShapeType.ENEMY
ShapeTypeBoss := ShapeType.BOSS
ShapeTypeBulletFromPlayer := ShapeType.BULLET_FROM_PLAYER
ShapeTypeBulletFromBoss := ShapeType.BULLET_FROM_BOSS

UNIT :: 64 // px => 1m
INITIAL_SCREEN_WIDTH :: 1280 / 2
INITIAL_SCREEN_HEIGHT :: 720 / 2
DEFAULT_VOLUME :: 0.5
grid_spacing: f32 = UNIT

BPS: f32 : (60.0 / 157.0)
