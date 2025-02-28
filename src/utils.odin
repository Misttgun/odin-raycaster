package main

import "core:fmt"
import "core:os"

pack_color :: proc(r: u8, g: u8, b: u8, a: u8 = 0xFF) -> u32 {
    color := u32(a) << 24 + u32(b) << 16 + u32(g) << 8 + u32(r)
    return color
}

unpack_color :: proc(color: u32) -> (r: u8, g: u8, b:u8, a:u8) {
    r = u8((color >> 0)  & 0xFF)
    g = u8((color >> 8)  & 0xFF)
    b = u8((color >> 16) & 0xFF)
    a = u8((color >> 24) & 0xFF)
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