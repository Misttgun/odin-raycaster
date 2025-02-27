package main

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

map_get :: proc(i, j : int) -> i32 {
    assert(i < map_w && j < map_h && len(game_map) == map_w * map_h)
    return i32(game_map[i + j * map_w] - '0')
}

map_is_empty :: proc(i, j : int) -> bool {
    assert(i < map_w && j < map_h && len(game_map) == map_w * map_h)
    return game_map[i + j * map_w] == ' '
}