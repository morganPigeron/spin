package main

import rl "vendor:raylib"

Track :: struct {
	music: rl.Music,
}

load_main_track :: proc() -> (track: Track) {
	track = {
		music = rl.LoadMusicStream(MAIN_THEME),
	}
	rl.SetMusicVolume(track.music, DEFAULT_VOLUME)
	return
}
