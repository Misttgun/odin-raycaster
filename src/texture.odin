package main

import "core:fmt"
import stbi "vendor:stb/image"

texture :: struct {
    img_w: i32, // Overall image dimensions
    img_h: i32,
    count: i32, // Number of textures and size in pixels
    size: i32,
    img: [dynamic]u32 // Textures storage container
}

texture_init :: proc(filename: cstring, tex: ^texture){
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

    tex.count = w / h
    tex.size = w / tex.count
    tex.img_w = w
    tex.img_h = h

    tex.img = make([dynamic]u32, w * h)
    for j in 0..< h {
        for i in 0..< w {
            r : u8 = pixmap[(i + j * w) * 4 + 0]
            g : u8 = pixmap[(i + j * w) * 4 + 1]
            b : u8 = pixmap[(i + j * w) * 4 + 2]
            a : u8 = pixmap[(i + j * w) * 4 + 3]
            
            tex.img[i + j * w] = pack_color(r, g, b, a)
        }
    }
}

texture_get :: proc(tex : texture, i, j, idx : i32)-> u32 {
    assert(i < tex.size && j < tex.size && idx < tex.count)
    return tex.img[i + idx * tex.size + j * tex.img_w]
}

texture_get_scaled_column :: proc(tex : texture, texture_id, texcoord, column_height : i32) -> [dynamic]u32 {
    assert(texcoord < tex.size && texture_id < tex.count)

    column := make([dynamic]u32, column_height)
    for y in 0..<column_height {
        column[y] = texture_get(tex, texcoord, (y * tex.size) / column_height, texture_id)
    }

    return column
}