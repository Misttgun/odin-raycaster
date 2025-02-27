package main

WIDTH :: 1024
HEIGHT :: 512

frame_buffer : [WIDTH * HEIGHT]u32

draw_rectangle :: proc(x, y, w, h : int, color: u32) {
    assert(len(frame_buffer) == WIDTH * HEIGHT)

    for i := 0; i < w; i += 1 {
        for j := 0; j < h; j += 1 {
            cx := x + i
            cy := y + j
            if cx >= WIDTH || cy >= HEIGHT { // No need to check for negative values, (usigned variables)
                continue
            }

            set_pixel(cx, cy, color)
        }
    }
}

set_pixel :: proc(x, y : int, color : u32) {
    assert(len(frame_buffer) == WIDTH * HEIGHT && x < WIDTH && y < HEIGHT)
    frame_buffer[x + y * WIDTH] = color
}

clear :: proc(color : u32) {
    // Set the image to color
    for i in 0..<len(frame_buffer) {
        frame_buffer[i] = color
    }
}