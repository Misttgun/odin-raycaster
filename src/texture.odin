package main

import "core:fmt"
import stbi "vendor:stb/image"


Texture :: struct {
    img_w: i32, // Overall image dimensions
    img_h: i32,
    count: i32, // Number of textures and size in pixels
    size: i32,
    img: [dynamic]u32 // Textures storage container
}

Sprite :: struct {
    x : f32,
    y : f32,
    tex_id : i32,
    player_dist : f32,
}

texture_init :: proc(filename: cstring, texture: ^Texture){
    n_channels : i32 = -1
    w, h : i32
    pixmap := stbi.load(filename, &w, &h, &n_channels, 0)
    defer stbi.image_free(pixmap)

    if pixmap == nil {
        fmt.eprintln("Error: can not load the textures")
        return
    }

    if n_channels != 4 {
        fmt.eprintln("Error: the texture must be a 32 bit image")
        return
    }

    if w != h * i32(w / h) {
        fmt.eprintln("Error: the texture file must contain N square textures packed horizontally")
        return
    }

    texture.count = w / h
    texture.size = w / texture.count
    texture.img_w = w
    texture.img_h = h

    texture.img = make([dynamic]u32, w * h)
    for j in 0..< h {
        for i in 0..< w {
            r : u8 = pixmap[(i + j * w) * 4 + 0]
            g : u8 = pixmap[(i + j * w) * 4 + 1]
            b : u8 = pixmap[(i + j * w) * 4 + 2]
            a : u8 = pixmap[(i + j * w) * 4 + 3]
            
            texture.img[i + j * w] = pack_color(r, g, b, a)
        }
    }
}

texture_get :: proc(texture : Texture, i, j, idx : i32)-> u32 {
    assert(i < texture.size && j < texture.size && idx < texture.count)
    return texture.img[i + idx * texture.size + j * texture.img_w]
}

texture_get_scaled_column :: proc(texture : Texture, texture_id, texcoord, column_height : i32) -> [dynamic]u32 {
    assert(texcoord < texture.size && texture_id < texture.count)

    column := make([dynamic]u32, column_height)
    for y in 0..<column_height {
        column[y] = texture_get(texture, texcoord, (y * texture.size) / column_height, texture_id)
    }

    return column
}

sprite_less :: proc(a, b : Sprite) -> bool {
    return a.player_dist > b.player_dist
}