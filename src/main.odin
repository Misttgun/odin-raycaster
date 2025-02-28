package main

import "core:fmt"
import "core:math"
import "core:slice"
import "core:time"

import SDL "vendor:sdl2"

should_quit := false

Player :: struct {
    x : f32, // Position
    y : f32,
    a : f32, // View direction
    fov : f32, // Field of view
    turn : i32,
    walk : i32,
}

main :: proc() {
    player := Player{x = 3.456, y = 2.345, a = 1.523, fov = math.PI / 3}

    tex_walls : Texture
    texture_init("./assets/walltext.png", &tex_walls)
    defer delete(tex_walls.img)

    if tex_walls.count == 0 {
        fmt.eprintln("Failed to load wall textures")
        return
    }

    tex_monster : Texture
    texture_init("./assets/monsters.png", &tex_monster)
    defer delete(tex_monster.img)

    if tex_monster.count == 0 {
        fmt.eprintln("Failed to load monster textures")
        return
    }

    sprites : [5]Sprite = {
        {3.523, 3.812, 2, 0},
        {1.834, 8.765, 0, 0},
        {5.323, 5.365, 1, 0},
        {14.32, 13.36, 3, 0},
        {4.123, 10.76, 1, 0}
    }

    assert(SDL.Init({.VIDEO}) == 0, SDL.GetErrorString())
    defer SDL.Quit()

    window : ^SDL.Window
    renderer : ^SDL.Renderer
    SDL.CreateWindowAndRenderer(i32(WIDTH), i32(HEIGHT), SDL.WINDOW_SHOWN | SDL.WINDOW_INPUT_FOCUS, &window, &renderer)
    defer SDL.DestroyWindow(window)
    defer SDL.DestroyRenderer(renderer)

    frame_buffer_texture := SDL.CreateTexture(renderer, .ABGR8888, .STREAMING, i32(WIDTH), i32(HEIGHT))
    defer SDL.DestroyTexture(frame_buffer_texture)

    timer_init(60)
    input_init()

    for should_quit == false {
        timer_update()

        event : SDL.Event
        for SDL.PollEvent(&event) {
            if event.type == .QUIT {
                should_quit = true
            }
        }

        input_update()
        handle_input(&player)
        player_update(&player, delta_time)

        for i in 0..<len(sprites) {
            sprites[i].player_dist = math.sqrt(math.pow(player.x - sprites[i].x, 2) + math.pow(player.y - sprites[i].y, 2)) // Distance from the player to the sprite
        }
    
        slice.sort_by(sprites[:], sprite_less) // Sort it from farthest to closest

        render(player, sprites[:], tex_walls, tex_monster)

        SDL.UpdateTexture(frame_buffer_texture, nil, raw_data(&frame_buffer), i32(WIDTH * 4))

        SDL.RenderClear(renderer)
        SDL.RenderCopy(renderer, frame_buffer_texture, nil, nil)
        SDL.RenderPresent(renderer)

        timer_update_late()
    }
}

handle_input :: proc(player : ^Player){
    if input_state.escape == .PRESSED {
        should_quit = true
    }

    player.turn = 0
    player.walk = 0

    if input_state.left == .PRESSED || input_state.left == .HELD {
        player.turn = -1
    }

    if input_state.right == .PRESSED || input_state.right == .HELD {
        player.turn = 1
    }

    if input_state.up == .PRESSED || input_state.up == .HELD {
        player.walk = 1
    }

    if input_state.down == .PRESSED || input_state.down == .HELD {
        player.walk = -1
    }
}

player_update :: proc(player : ^Player, dt : f32) {
    player.a += f32(player.turn) * dt
    nx := player.x + f32(player.walk) * math.cos(player.a) * dt
    ny := player.y + f32(player.walk) * math.sin(player.a) * dt

    if int(nx) >= 0 && int(nx) < map_w && int(ny) >= 0 && int(ny) < map_h {
        if map_is_empty(int(nx), int(player.y)) do player.x = nx
        if map_is_empty(int(player.x), int(ny)) do player.y = ny
    }
}