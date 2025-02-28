package main

map_w := 16
map_h := 16
game_map := "0000222222220000"+
            "1              5"+
            "1              5"+
            "1     01111    5"+
            "0     0        5"+
            "0     3     1155"+
            "0   1000       5"+
            "0   3  0       5"+
            "5   4  100011  5"+
            "5   4   1      4"+
            "0       1      4"+
            "2       1  44444"+
            "0     000      4"+
            "0 111          4"+
            "0              4"+
            "0002222244444444"

map_get :: proc(i, j : int) -> i32 {
    assert(i < map_w && j < map_h && len(game_map) == map_w * map_h)
    return i32(game_map[i + j * map_w] - '0')
}

map_is_empty :: proc(i, j : int) -> bool {
    assert(i < map_w && j < map_h && len(game_map) == map_w * map_h)
    return game_map[i + j * map_w] == ' '
}

map_show_sprite :: proc(sprite_t : Sprite) {
    rect_w := WIDTH / (map_w * 2)
    rect_h := HEIGHT / map_h
    draw_rectangle(int(sprite_t.x * f32(rect_w)) - 3, int(sprite_t.y * f32(rect_h)) - 3, 6, 6, pack_color(255, 0, 0))
}