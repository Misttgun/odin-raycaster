package main

import "core:math"

wall_x_texcoord :: proc(hitx, hity : f32, tex_walls : Texture) -> i32 {
    x : f32 = hitx - math.floor(hitx + 0.5) // x and y contain (signed) fractional parts of hitx and hity
    y : f32 = hity - math.floor(hity + 0.5) // They vary between -0.5 and +0.5, and one of them is supposed to be very close to 0
    tex_coord := i32(x * f32(tex_walls.size))

    // We need to determine wether we hit a "vertical" or a "horizontal" wall (w.r.t the map)
    if math.abs(y) > math.abs(x) {
        tex_coord = i32(y * f32(tex_walls.size))
    }

    // Do not forget x_tex_coord can be negative, fix that
    if tex_coord < 0 {
        tex_coord += tex_walls.size
    }

    assert(tex_coord >= 0 && tex_coord < tex_walls.size)

    return tex_coord
}

draw_map :: proc(sprites : []Sprite, tex_walls : Texture, cell_w, cell_h : int) {
    for j := 0; j < map_h; j += 1 { // Draw the map
        for i := 0; i < map_w; i += 1 {
            if map_is_empty(i, j){ // Skip empty spaces
                continue
            }

            rect_x := i * cell_w
            rect_y := j * cell_h
            tex_id := map_get(i, j)
            assert(tex_id < tex_walls.count)

            draw_rectangle(rect_x, rect_y, cell_w, cell_w, texture_get(tex_walls, 0, 0, tex_id)) // The color is taken from the upper left pixel of the texture
        }
    }

    // Draw the sprites
    for i in 0..<len(sprites) {
        map_show_sprite(sprites[i])
    }
}

draw_sprite :: proc(sprite : Sprite, depth_buffer : []f32, player : Player, tex_sprites : Texture) {
    // Absolute direction from the player to the sprite (in radians)
    sprite_dir := math.atan2(sprite.y - player.y, sprite.x - player.x)

    // Remove unecessary periods from the relative direction
    for sprite_dir - player.a > math.PI {
        sprite_dir -= 2 * math.PI
    }

    for sprite_dir - player.a < -math.PI {
        sprite_dir += 2 * math.PI
    }

    sprite_screen_size := math.min(1000, int(f32(HEIGHT) / sprite.player_dist)) // Screen sprite size

    h_offset : int = int((sprite_dir - player.a) / player.fov * (WIDTH / 2) + (WIDTH / 2) / 2) - int(tex_sprites.size / 2) // Do not forget the 3D view takes only a half of the framebuffer
    v_offset : int = HEIGHT / 2 - sprite_screen_size / 2

    for i in 0..<sprite_screen_size {
        if h_offset + i < 0 || h_offset + i >= WIDTH / 2 do continue
        if depth_buffer[h_offset + i] < sprite.player_dist do continue

        for j in 0..<sprite_screen_size {
            if v_offset + j < 0 || v_offset + j >= HEIGHT do continue

            color := texture_get(tex_sprites, i32(i) * tex_sprites.size / i32(sprite_screen_size), i32(j) * tex_sprites.size / i32(sprite_screen_size), sprite.tex_id)
            r, g, b, a := unpack_color(color)
            if a > 128 {
                set_pixel(WIDTH / 2 + h_offset + i, v_offset + j, color)
            }
        }
    }
}


render :: proc(player : Player, sprites : []Sprite, tex_walls : Texture, tex_monst : Texture) {
    clear(pack_color(255, 255, 255)) // Clear the screen

    cell_w := WIDTH / (map_w * 2)
    cell_h := HEIGHT / map_h

    depth_buffer : [WIDTH / 2]f32
    for i in 0..<len(depth_buffer) {
        depth_buffer[i] = 1e3
    }

    // Draw the visibility cone and the "3D" view
    for i := 0; i < WIDTH / 2; i += 1 {
        angle := player.a - player.fov / 2 + player.fov * f32(i) / f32(WIDTH / 2)

        for t : f32 = 0; t < 20; t += 0.01 {
            x := player.x + t * math.cos(angle)
            y := player.y + t * math.sin(angle)

            set_pixel(int(x * f32(cell_w)), int(y * f32(cell_h)), pack_color(160, 160, 160)) // This draws the visibility cone

            if map_is_empty(int(x), int(y)) { 
                continue
            }
                
            tex_id := map_get(int(x), int(y)) // Our ray touches a wall, so draw the vertical column to create an illusion of 3D
            assert(tex_id < tex_walls.count)

            dist := t * math.cos(angle - player.a)
            depth_buffer[i] = dist

            column_height := i32(f32(HEIGHT) / dist)
            x_texcoord := wall_x_texcoord(x, y, tex_walls)
            
            column := texture_get_scaled_column(tex_walls, tex_id, x_texcoord, column_height)
            defer delete(column)

            pix_x := i + WIDTH / 2
            for j in 0..<column_height {
                pix_y := int(j + HEIGHT / 2 - column_height / 2)
                if pix_y >= 0 && pix_y < HEIGHT {
                    set_pixel(pix_x, pix_y, column[j])
                }
            }
            break
        }
    }

    draw_map(sprites[:], tex_walls, cell_w, cell_h)

    // Draw the sprites
    for i in 0..<len(sprites) {
        draw_sprite(sprites[i], depth_buffer[:], player, tex_monst)
    }
}