package main

import rl "vendor:raylib"

Track :: struct {
	music: rl.Music,
}

load_main_track :: proc() -> Track {
	return {music = rl.LoadMusicStream(MAIN_THEME)}
}
