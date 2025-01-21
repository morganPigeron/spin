#+feature dynamic-literals

package main

import rl "vendor:raylib"

Sounds :: enum {
    BAD_SPIN,
    BAD_SPIN_2,
    GOOD_SPIN,
    GOOD_SPIN_2,
    MAIN_THEME,
    MAIN_THEME_2,
    ATTACK_FX_1,
    ATTACK_FX_2,
    ATTACK_FX_3,
    JUMP_FX_1,
    JUMP_FX_2,
    JUMP_FX_3,
    WALKING_FX_1,
    WALKING_FX_2,
    WALKING_FX_3,
}

DATA_BAD_SPIN := #load("assets/BAD SPIN.mp3")
DATA_BAD_SPIN_2 := #load("assets/BAD SPIN 2.wav")
DATA_GOOD_SPIN := #load("assets/GOOD SPIN.mp3")
DATA_GOOD_SPIN_2 := #load("assets/GOOD SPIN 2.wav")
DATA_MAIN_THEME := #load("assets/MAIN THEME.mp3")
DATA_MAIN_THEME_2 := #load("assets/MAIN THEME 2.wav")
DATA_ATTACK_FX_1 := #load("assets/ATTACK FX 1.wav")
DATA_ATTACK_FX_2 := #load("assets/ATTACK FX 2.wav")
DATA_ATTACK_FX_3 := #load("assets/ATTACK FX 3.wav")
DATA_JUMP_FX_1 := #load("assets/JUMP FX 1.wav")
DATA_JUMP_FX_2 := #load("assets/JUMP FX 2.wav")
DATA_JUMP_FX_3 := #load("assets/JUMP FX 3.wav")
DATA_WALKING_FX_1 := #load("assets/WALKING FX 1.wav")
DATA_WALKING_FX_2 := #load("assets/WALKING FX 2.wav")
DATA_WALKING_FX_3 := #load("assets/WALKING FX 3.wav")

SoundsList: map[Sounds]rl.Music
load_sounds :: proc () {
    SoundsList = {
	    .BAD_SPIN     = rl.LoadMusicStreamFromMemory(
		".mp3",
		raw_data(DATA_BAD_SPIN),
		i32(len(DATA_BAD_SPIN)),
	    ),
	    .BAD_SPIN_2   = rl.LoadMusicStreamFromMemory(
		".wav",
		raw_data(DATA_BAD_SPIN_2),
		i32(len(DATA_BAD_SPIN_2)),
	    ),
	    .GOOD_SPIN    = rl.LoadMusicStreamFromMemory(
		".mp3",
		raw_data(DATA_GOOD_SPIN),
		i32(len(DATA_GOOD_SPIN)),
	    ),
	    .GOOD_SPIN_2  = rl.LoadMusicStreamFromMemory(
		".wav",
		raw_data(DATA_GOOD_SPIN_2),
		i32(len(DATA_GOOD_SPIN_2)),
	    ),
	    .MAIN_THEME   = rl.LoadMusicStreamFromMemory(
		".mp3",
		raw_data(DATA_MAIN_THEME),
		i32(len(DATA_MAIN_THEME)),
	    ),
	    .MAIN_THEME_2 = rl.LoadMusicStreamFromMemory(
		".wav",
		raw_data(DATA_MAIN_THEME_2),
		i32(len(DATA_MAIN_THEME_2)),
	    ),
	    .ATTACK_FX_1  = rl.LoadMusicStreamFromMemory(
		".wav",
		raw_data(DATA_ATTACK_FX_1),
		i32(len(DATA_ATTACK_FX_1)),
	    ),
	    .ATTACK_FX_2  = rl.LoadMusicStreamFromMemory(
		".wav",
		raw_data(DATA_ATTACK_FX_2),
		i32(len(DATA_ATTACK_FX_2)),
	    ),
	    .ATTACK_FX_3  = rl.LoadMusicStreamFromMemory(
		".wav",
		raw_data(DATA_ATTACK_FX_3),
		i32(len(DATA_ATTACK_FX_3)),
	    ),
	    .JUMP_FX_1    = rl.LoadMusicStreamFromMemory(
		".wav",
		raw_data(DATA_JUMP_FX_1),
		i32(len(DATA_JUMP_FX_1)),
	    ),
	    .JUMP_FX_2    = rl.LoadMusicStreamFromMemory(
		".wav",
		raw_data(DATA_JUMP_FX_2),
		i32(len(DATA_JUMP_FX_2)),
	    ),
	    .JUMP_FX_3    = rl.LoadMusicStreamFromMemory(
		".wav",
		raw_data(DATA_JUMP_FX_3),
		i32(len(DATA_JUMP_FX_3)),
	    ),
	    .WALKING_FX_1 = rl.LoadMusicStreamFromMemory(
		".wav",
		raw_data(DATA_WALKING_FX_1),
		i32(len(DATA_WALKING_FX_1)),
	    ),
	    .WALKING_FX_2 = rl.LoadMusicStreamFromMemory(
		".wav",
		raw_data(DATA_WALKING_FX_2),
		i32(len(DATA_WALKING_FX_2)),
	    ),
	    .WALKING_FX_3 = rl.LoadMusicStreamFromMemory(
		".wav",
		raw_data(DATA_WALKING_FX_3),
		i32(len(DATA_WALKING_FX_3)),
	    ),
    }
}

GLASSES :: "assets/GJ1_glasses.png"
CIG :: "assets/GJ1_cig.png"
SUGAR :: "assets/GJ1_sugar.png"

PLANT :: "assets/GJ1_plant1_OL.png"
CUBICLE :: "assets/GJ1_cubicle.png"
PRINTER :: "assets/GJ1_printer.png"
CHARACTER :: "assets/mainchara.png"
BOY1 :: "assets/GJ1_char1.png"
GIRL1 :: "assets/GJ1_char2.png"
GIRL2 :: "assets/GJ1_char3.png"

Assets :: enum {
    GLASSES,
    CIG,
    SUGAR,
    PLANT,
    CUBICLE,
    CHARACTER,
    PRINTER,
    BOY1,
    GIRL1,
    GIRL2,
}
