package main

import "core:fmt"
import "core:os"
import "core:math"
import "core:math/rand"

WIDTH :: 1024
HEIGHT :: 512
FOV :: math.PI / 3

frame_buffer := make([dynamic]u32, WIDTH * HEIGHT)

main :: proc() {
    // Set the image to white
    for i in 0..<len(frame_buffer) {
        frame_buffer[i] = pack_color(255, 255, 255)
    }

    map_w := 16
    map_h := 16
    game_map := "0000222222220000"+
                "1              0"+
                "1      11111   0"+
                "1     0        0"+
                "0     0  1110000"+
                "0     3        0"+
                "0   10000      0"+
                "0   0   11100  0"+
                "0   0   0      0"+
                "0   0   1  00000"+
                "0       1      0"+
                "2       1      0"+
                "0       0      0"+
                "0 0000000      0"+
                "0              0"+
                "0002222222200000"
    
    assert(len(game_map) == map_w * map_h)

    player_x : f32 = 3.456 // Player x position
    player_y : f32 = 2.345 // Player y position
    player_a : f32 = 1.523 // Player view direction

    n_colors :: 10
    colors : [n_colors]u32

    for i in 0..< n_colors {
        colors[i] = pack_color(u8(rand.uint32() % 255), u8(rand.uint32() % 255), u8(rand.uint32() % 255))
    }

    rect_w := WIDTH / (map_w * 2)
    rect_h := HEIGHT / map_h

    for j := 0; j < map_h; j += 1 {
        for i := 0; i < map_w; i += 1 {
            if game_map[i + j * map_w] == ' '{
                continue
            }

            rect_x := i * rect_w
            rect_y := j * rect_h

            i_color := game_map[i + j * map_w] - '0'
            assert(i_color < n_colors)

            draw_rectangle(&frame_buffer, WIDTH, HEIGHT, rect_x, rect_y, rect_w, rect_h, colors[i_color])
        }
    }

    // Draw the visibility cone and the "3D" view
    for i := 0; i < WIDTH / 2; i += 1 {
        angle := player_a - FOV / 2 + FOV * f32(i) / f32(WIDTH / 2)

        for t : f32 = 0; t < 20; t += 0.01 {
            cx := player_x + t * math.cos(angle)
            cy := player_y + t * math.sin(angle)
            
            pix_x := int(cx * f32(rect_w))
            pix_y := int(cy * f32(rect_h))

            frame_buffer[pix_x + pix_y * WIDTH] = pack_color(160, 160, 160) // This draws the visibility cone

            if game_map[int(cx) + int(cy) * map_w] != ' '{ // Our ray touches a wall, so draw the vertical column to create an illusion of 3D
                i_color := game_map[int(cx) + int(cy) * map_w] - '0'
                assert(i_color < n_colors)

                column_height := int(f32(HEIGHT) / t * math.cos(angle - player_a))
                draw_rectangle(&frame_buffer, WIDTH, HEIGHT, WIDTH / 2 + i, HEIGHT / 2 - column_height / 2, 1, column_height, colors[i_color])
                break
            }

        }
    }

    drop_ppm_image("./bin/out.ppm", frame_buffer[:], WIDTH, HEIGHT)

}

pack_color :: proc(r: u8, g: u8, b: u8, a: u8 = 0xFF) -> u32 {
    color := u32(a) << 24 + u32(b) << 16 + u32(g) << 8 + u32(r)
    return color
}

unpack_color :: proc(color: u32) -> (r: u8, g: u8, b:u8, a:u8) {
    r = u8((color >> 0)  & 0xFF)
    g = u8((color >> 8)  & 0xFF)
    b = u8((color >> 16) & 0xFF)
    a = u8((color >> 32) & 0xFF)
    return
}

drop_ppm_image :: proc(filename: string, image: []u32, w: int, h: int) {
    assert(len(image) == w * h)

    // Open file for binary writing
    file, err := os.open(filename, os.O_RDWR | os.O_CREATE)
    if err != nil {
        fmt.eprintln("Error opening file: ", err)
        return
    }
    defer os.close(file)

    // Write header
    header := fmt.aprint("P6\n", w, " ", h, "\n255\n", sep = "")
    os.write_string(file, header)

    for i := 0; i < h * w; i+= 1 {
        r, g, b, a := unpack_color(image[i])
        os.write_byte(file, r)
        os.write_byte(file, g)
        os.write_byte(file, b)
    }
}

draw_rectangle :: proc(img : ^[dynamic]u32, img_w: int, img_h: int, x: int, y: int, w: int, h: int, color: u32) {
    assert(len(img) == img_w * img_h)

    for i := 0; i < w; i += 1 {
        for j := 0; j < h; j += 1 {
            cx := x + i
            cy := y + j
            if cx >= img_w || cy >= img_h { // No need to check for negative values, (usigned variables)
                continue
            }

            img[cx + cy * img_w] = color
        }
    }
}