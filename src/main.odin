package main

import "core:fmt"
import "core:math"

main :: proc() {
    m_player := player{x = 3.456, y = 2.345, a = 1.523, fov = math.PI / 3}

    tex_walls : texture
    texture_init("./assets/walltext.png", &tex_walls)
    defer delete(tex_walls.img)

    if tex_walls.count == 0 {
        fmt.eprintln("Failed to load wall textures")
        return
    }

    render(m_player, tex_walls)
    drop_ppm_image("./bin/out.ppm", frame_buffer[:], WIDTH, HEIGHT)

}

wall_x_texcoord :: proc(x, y : f32, tex_walls : texture) -> i32 {
    hit_x : f32 = x - math.floor(x + 0.5) // hit_x and hit_y contain (signed) fractional parts of cx and cy
    hit_y : f32 = y - math.floor(y + 0.5) // They vay between -0.5 and +0.5, and one of them is supposed to be very close to 0
    tex_coord := i32(hit_x * f32(tex_walls.size))

    // We need to determine wether we hit a "vertical" or a "horizontal" wall (w.r.t the map)
    if math.abs(hit_y) > math.abs(hit_x) {
        tex_coord = i32(hit_y * f32(tex_walls.size))
    }

    // Do not forget x_tex_coord can be negative, fix that
    if tex_coord < 0 {
        tex_coord += tex_walls.size
    }

    assert(tex_coord >= 0 && tex_coord < tex_walls.size)

    return tex_coord
}

render :: proc(player_t : player, tex_walls : texture) {
    clear(pack_color(255, 255, 255)) // Clear the screen

    rect_w := WIDTH / (map_w * 2)
    rect_h := HEIGHT / map_h

    for j := 0; j < map_h; j += 1 { // Draw the map
        for i := 0; i < map_w; i += 1 {
            if map_is_empty(i, j){ // Skip empty spaces
                continue
            }

            rect_x := i * rect_w
            rect_y := j * rect_h
            tex_id := map_get(i, j)
            assert(tex_id < tex_walls.count)

            draw_rectangle(rect_x, rect_y, rect_w, rect_h, tex_walls.img[tex_id * tex_walls.size]) // The color is taken from the upper left pixel of the texture
        }
    }

    // Draw the visibility cone and the "3D" view
    for i := 0; i < WIDTH / 2; i += 1 {
        angle := player_t.a - player_t.fov / 2 + player_t.fov * f32(i) / f32(WIDTH / 2)

        for t : f32 = 0; t < 20; t += 0.01 {
            x := player_t.x + t * math.cos(angle)
            y := player_t.y + t * math.sin(angle)

            set_pixel(int(x * f32(rect_w)), int(y * f32(rect_h)), pack_color(160, 160, 160)) // This draws the visibility cone

            if map_is_empty(int(x), int(y)) { 
                continue
            }
                
            tex_id := map_get(int(x), int(y)) // Our ray touches a wall, so draw the vertical column to create an illusion of 3D
            assert(tex_id < tex_walls.count)

            column_height := i32(f32(HEIGHT) / (t * math.cos(angle - player_t.a)))
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
}