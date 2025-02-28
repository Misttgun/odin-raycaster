package main

import SDL "vendor:sdl2"

delta_time: f32

@(private)
now, last, frame_last, frame_delay, frame_time: f32

@(private)
frame_rate, frame_count: u32

timer_init :: proc(frame_per_sec: u32) {
    frame_rate = frame_per_sec
    frame_delay = 1000.0 / f32(frame_rate)
}

timer_update :: proc() {
    now = f32(SDL.GetTicks())
    delta_time = (now - last) / 1000.0
    last = now
    frame_count += 1

    if now - frame_last >= 1000.0 {
        frame_rate = frame_count
        frame_count = 0
        frame_last = now
    }
}

timer_update_late :: proc() {
    frame_time = f32(SDL.GetTicks()) - now

    if frame_delay > frame_time {
        delay := u32(frame_delay - frame_time)
        SDL.Delay(delay)
    }
}