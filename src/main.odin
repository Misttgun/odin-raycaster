package main

import "core:fmt"
import "core:os"
import "core:math"
import "core:math/rand"
import stbi "vendor:stb/image"

WIDTH :: 1024
HEIGHT :: 512
FOV :: math.PI / 3

frame_buffer : [WIDTH * HEIGHT]u32

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
                "0   3   11100  0"+
                "5   4   0      0"+
                "5   4   1  00000"+
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

    wall_tex_size : i32 // Texture dimensions (it is a square)
    wall_tex_cnt : i32 // Number of different textures in the image
    is_loaded, wall_tex := load_texture("./assets/walltext.png", &wall_tex_size, &wall_tex_cnt)
    if is_loaded == false {
        fmt.eprintln("Failed to load wall textures")
        return
    }

    defer delete(wall_tex)

    rect_w := WIDTH / (map_w * 2)
    rect_h := HEIGHT / map_h

    for j := 0; j < map_h; j += 1 { // Draw the map
        for i := 0; i < map_w; i += 1 {
            if game_map[i + j * map_w] == ' '{ // Skip empty spaces
                continue
            }

            rect_x := i * rect_w
            rect_y := j * rect_h

            tex_id := i32(game_map[i + j * map_w] - '0')
            assert(tex_id < wall_tex_cnt)

            draw_rectangle(frame_buffer[:], WIDTH, HEIGHT, rect_x, rect_y, rect_w, rect_h, wall_tex[tex_id * wall_tex_size]) // The color is taken from the upper left pixel of the texture
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
                tex_id := i32(game_map[int(cx) + int(cy) * map_w] - '0')
                assert(tex_id < wall_tex_cnt)

                column_height := int(f32(HEIGHT) / (t * math.cos(angle - player_a)))

                hit_x : f32 = cx - math.floor(cx + 0.5) // hit_x and hit_y contain (signed) fractional parts of cx and cy
                hit_y : f32 = cy - math.floor(cy + 0.5) // They vay between -0.5 and +0.5, and one of them is supposed to be very close to 0
                x_tex_coord := int(hit_x * f32(wall_tex_size))
                if math.abs(hit_y) > math.abs(hit_x) { // We need to determine wether we hit a "vertical" or a "horizontal" wall (w.r.t the map)
                    x_tex_coord = int(hit_y * f32(wall_tex_size))
                }

                if x_tex_coord < 0 { // Do not forget x_tex_coord can be negative, fix that
                    x_tex_coord += int(wall_tex_size)
                }

                assert(x_tex_coord >= 0 && x_tex_coord < int(wall_tex_size))

                column := texture_column(wall_tex[:], int(wall_tex_size), int(wall_tex_cnt), int(tex_id), x_tex_coord, column_height)
                defer delete(column)

                pix_x = WIDTH / 2 + i
                for j in 0..<column_height {
                    pix_y = j + HEIGHT / 2 - column_height / 2
                    if pix_y < 0 || pix_y >= HEIGHT {
                        continue
                    }

                    frame_buffer[pix_x + pix_y * WIDTH] = column[j]
                }

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

draw_rectangle :: proc(img : []u32, img_w: int, img_h: int, x: int, y: int, w: int, h: int, color: u32) {
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

load_texture :: proc(filename : cstring, tex_size : ^i32, tex_cnt : ^i32) -> (bool, [dynamic]u32) {
    n_channels : i32 = -1
    w, h : i32
    pixmap := stbi.load(filename, &w, &h, &n_channels, 0)
    defer stbi.image_free(pixmap)
    if pixmap == nil {
        fmt.eprintln("Error: can not load the textures")
        return false, nil
    }

    if n_channels != 4 {
        fmt.eprintln("Error: the texture must be a 32 bit image")
        return false, nil
    }

    tex_cnt^ = w / h
    tex_size^ = w / tex_cnt^
    if w != h * tex_cnt^ {
        fmt.eprintln("Error: the texture file must contain N square textures packed horizontally")
        return false, nil
    }

    texture := make([dynamic]u32, w * h)
    for j in 0..< h {
        for i in 0..< w {
            r : u8 = pixmap[(i + j * w) * 4 + 0]
            g : u8 = pixmap[(i + j * w) * 4 + 1]
            b : u8 = pixmap[(i + j * w) * 4 + 2]
            a : u8 = pixmap[(i + j * w) * 4 + 3]
            
            texture[i + j * w] = pack_color(r, g, b, a)
        }
    }

    return true, texture
}

texture_column :: proc(img : []u32, tex_size , n_textures, tex_id, tex_coord, column_height: int) -> [dynamic]u32 {
    img_w := tex_size * n_textures
    img_h := tex_size

    assert(len(img) == img_w * img_h && tex_coord < tex_size && tex_id < n_textures)

    column := make([dynamic]u32, column_height)
    for y in 0..<column_height {
        pix_x := tex_id * tex_size + tex_coord
        pix_y := (y * tex_size) / column_height
        column[y] = img[pix_x + pix_y * img_w]
    }

    return column
}