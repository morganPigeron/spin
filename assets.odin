#+feature dynamic-literals

package main

import rl "vendor:raylib"

Sounds :: enum {
    BAD_SPIN,
    BAD_SPIN_FINAL,
    GOOD_SPIN,
    GOOD_SPIN_FINAL,
    MAIN_THEME,
    MAIN_THEME_2,
    ATTACK_1,
    ATTACK_2,
    ATTACK_3,
    JUMP_1,
    JUMP_2,
    JUMP_3,
    WALKING_1,
    WALKING_2,
    WALKING_3,
}

DATA_BAD_SPIN := #load("assets/BAD SPIN.mp3")
DATA_BAD_SPIN_FINAL := #load("assets/BAD SPIN FINAL.mp3")
DATA_GOOD_SPIN := #load("assets/GOOD SPIN.mp3")
DATA_GOOD_SPIN_FINAL := #load("assets/GOOD SPIN FINAL.mp3")
DATA_MAIN_THEME := #load("assets/MAIN THEME.mp3")
DATA_MAIN_THEME_2 := #load("assets/MAIN THEME 2.mp3")
DATA_ATTACK_1 := #load("assets/ATTACK 1.mp3")
DATA_ATTACK_2 := #load("assets/ATTACK 2.mp3")
DATA_ATTACK_3 := #load("assets/ATTACK 3.mp3")
DATA_JUMP_1 := #load("assets/JUMP 1.mp3")
DATA_JUMP_2 := #load("assets/JUMP 2.mp3")
DATA_JUMP_3 := #load("assets/JUMP 3.mp3")
DATA_WALKING_1 := #load("assets/WALKING 1.mp3")
DATA_WALKING_2 := #load("assets/WALKING 2.mp3")
DATA_WALKING_3 := #load("assets/WALKING 3.mp3")

SoundsList: map[Sounds]rl.Music
delete_sounds :: proc() {
    delete(SoundsList)
}
load_sounds :: proc() {
    SoundsList = {
	    .BAD_SPIN     = rl.LoadMusicStreamFromMemory(
		".mp3",
		raw_data(DATA_BAD_SPIN),
		i32(len(DATA_BAD_SPIN)),
	    ),
	    .BAD_SPIN_FINAL   = rl.LoadMusicStreamFromMemory(
		".mp3",
		raw_data(DATA_BAD_SPIN_FINAL),
		i32(len(DATA_BAD_SPIN_FINAL)),
	    ),
	    .GOOD_SPIN    = rl.LoadMusicStreamFromMemory(
		".mp3",
		raw_data(DATA_GOOD_SPIN),
		i32(len(DATA_GOOD_SPIN)),
	    ),
	    .GOOD_SPIN_FINAL  = rl.LoadMusicStreamFromMemory(
		".mp3",
		raw_data(DATA_GOOD_SPIN_FINAL),
		i32(len(DATA_GOOD_SPIN_FINAL)),
	    ),
	    .MAIN_THEME   = rl.LoadMusicStreamFromMemory(
		".mp3",
		raw_data(DATA_MAIN_THEME),
		i32(len(DATA_MAIN_THEME)),
	    ),
	    .MAIN_THEME_2 = rl.LoadMusicStreamFromMemory(
		".mp3",
		raw_data(DATA_MAIN_THEME_2),
		i32(len(DATA_MAIN_THEME_2)),
	    ),
	    .ATTACK_1  = rl.LoadMusicStreamFromMemory(
		".mp3",
		raw_data(DATA_ATTACK_1),
		i32(len(DATA_ATTACK_1)),
	    ),
	    .ATTACK_2  = rl.LoadMusicStreamFromMemory(
		".mp3",
		raw_data(DATA_ATTACK_2),
		i32(len(DATA_ATTACK_2)),
	    ),
	    .ATTACK_3  = rl.LoadMusicStreamFromMemory(
		".mp3",
		raw_data(DATA_ATTACK_3),
		i32(len(DATA_ATTACK_3)),
	    ),
	    .JUMP_1    = rl.LoadMusicStreamFromMemory(
		".mp3",
		raw_data(DATA_JUMP_1),
		i32(len(DATA_JUMP_1)),
	    ),
	    .JUMP_2    = rl.LoadMusicStreamFromMemory(
		".mp3",
		raw_data(DATA_JUMP_2),
		i32(len(DATA_JUMP_2)),
	    ),
	    .JUMP_3    = rl.LoadMusicStreamFromMemory(
		".mp3",
		raw_data(DATA_JUMP_3),
		i32(len(DATA_JUMP_3)),
	    ),
	    .WALKING_1 = rl.LoadMusicStreamFromMemory(
		".mp3",
		raw_data(DATA_WALKING_1),
		i32(len(DATA_WALKING_1)),
	    ),
	    .WALKING_2 = rl.LoadMusicStreamFromMemory(
		".mp3",
		raw_data(DATA_WALKING_2),
		i32(len(DATA_WALKING_2)),
	    ),
	    .WALKING_3 = rl.LoadMusicStreamFromMemory(
		".mp3",
		raw_data(DATA_WALKING_3),
		i32(len(DATA_WALKING_3)),
	    ),
	    .GOOD_SPIN_FINAL = rl.LoadMusicStreamFromMemory(
		".mp3",
		raw_data(DATA_GOOD_SPIN_FINAL),
		i32(len(DATA_GOOD_SPIN_FINAL)),
	    ),
	    .BAD_SPIN_FINAL = rl.LoadMusicStreamFromMemory(
		".mp3",
		raw_data(DATA_BAD_SPIN_FINAL),
		i32(len(DATA_BAD_SPIN_FINAL)),
	    ),

    }
}

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
    STAPPLER,
    CARROT,
    WALL1,
    WALL2,
}

GLASSES := #load("assets/GJ1_glasses.png")
CIG := #load("assets/GJ1_cig.png")
SUGAR := #load("assets/GJ1_sugar.png")
PLANT := #load("assets/GJ1_plant1_OL.png")
CUBICLE := #load("assets/GJ1_cubicle.png")
PRINTER := #load("assets/GJ1_printer.png")
CHARACTER := #load("assets/mainchara.png")
BOY1 := #load("assets/GJ1_char1.png")
GIRL1 := #load("assets/GJ1_char2.png")
GIRL2 := #load("assets/GJ1_char3.png")
STAPPLER := #load("assets/GJ1_stappler.png")
CARROT := #load("assets/GJ1_carrot_OL.png")
WALL1 := #load("assets/GJ1_wall1.png")
WALL2 := #load("assets/GJ1_wall2.png")
AssetsList: map[Assets]rl.Texture2D

delete_textures :: proc() {
    delete(AssetsList)
}

load_textures :: proc() {
    AssetsList = {
	    .WALL1     = rl.LoadTextureFromImage(
		rl.LoadImageFromMemory(".png", raw_data(WALL1), i32(len(WALL1))),
	    ),
	    .WALL2     = rl.LoadTextureFromImage(
		rl.LoadImageFromMemory(".png", raw_data(WALL2), i32(len(WALL2))),
	    ),
	    .GLASSES   = rl.LoadTextureFromImage(
		rl.LoadImageFromMemory(".png", raw_data(GLASSES), i32(len(GLASSES))),
	    ),
	    .CIG       = rl.LoadTextureFromImage(
		rl.LoadImageFromMemory(".png", raw_data(CIG), i32(len(CIG))),
	    ),
	    .SUGAR     = rl.LoadTextureFromImage(
		rl.LoadImageFromMemory(".png", raw_data(SUGAR), i32(len(SUGAR))),
	    ),
	    .PLANT     = rl.LoadTextureFromImage(
		rl.LoadImageFromMemory(".png", raw_data(PLANT), i32(len(PLANT))),
	    ),
	    .CUBICLE   = rl.LoadTextureFromImage(
		rl.LoadImageFromMemory(".png", raw_data(CUBICLE), i32(len(CUBICLE))),
	    ),
	    .CHARACTER = rl.LoadTextureFromImage(
		rl.LoadImageFromMemory(".png", raw_data(CHARACTER), i32(len(CHARACTER))),
	    ),
	    .PRINTER   = rl.LoadTextureFromImage(
		rl.LoadImageFromMemory(".png", raw_data(PRINTER), i32(len(PRINTER))),
	    ),
	    .BOY1      = rl.LoadTextureFromImage(
		rl.LoadImageFromMemory(".png", raw_data(BOY1), i32(len(BOY1))),
	    ),
	    .GIRL1     = rl.LoadTextureFromImage(
		rl.LoadImageFromMemory(".png", raw_data(GIRL1), i32(len(GIRL1))),
	    ),
	    .GIRL2     = rl.LoadTextureFromImage(
		rl.LoadImageFromMemory(".png", raw_data(GIRL2), i32(len(GIRL2))),
	    ),
	    .STAPPLER  = rl.LoadTextureFromImage(
		rl.LoadImageFromMemory(".png", raw_data(STAPPLER), i32(len(STAPPLER))),
	    ),
	    .CARROT    = rl.LoadTextureFromImage(
		rl.LoadImageFromMemory(".png", raw_data(CARROT), i32(len(CARROT))),
	    ),
    }
}
