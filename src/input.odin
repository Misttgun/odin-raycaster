package main

import "core:fmt"
import "core:os"
import "core:strings"

import SDL "vendor:sdl2"

KeyState :: enum {
    UNPRESSED,
    PRESSED,
    HELD,
}

Key :: enum {
    LEFT,
    RIGHT,
    UP,
    DOWN,
    ESCAPE,
}

InputState :: struct {
    left: KeyState,
    right: KeyState,
    up: KeyState,
    down: KeyState,
    escape: KeyState,
}

ConfigState :: struct {
    keybinds: [5]u8,
}

config_state := ConfigState{}

input_state := InputState{}

input_init :: proc() {
    if config_load() == false {
        fmt.eprintln("Could not create or load config file.")
    }
}

input_update :: proc() {
    keyboard_state := SDL.GetKeyboardState(nil)

    input_update_key_state(keyboard_state[config_state.keybinds[Key.LEFT]], &input_state.left)
    input_update_key_state(keyboard_state[config_state.keybinds[Key.RIGHT]], &input_state.right)
    input_update_key_state(keyboard_state[config_state.keybinds[Key.UP]], &input_state.up)
    input_update_key_state(keyboard_state[config_state.keybinds[Key.DOWN]], &input_state.down)
    input_update_key_state(keyboard_state[config_state.keybinds[Key.ESCAPE]], &input_state.escape)
}


@(private = "file")
input_update_key_state :: proc(current_state: u8, key_state: ^KeyState) {
    if current_state != 0 {
        if key_state^ != .UNPRESSED {
            key_state^ = .HELD
        } else {
            key_state^ = .PRESSED
        }
    } else {
        key_state^ = .UNPRESSED
    }
}

@(private = "file")
config_load :: proc() -> bool {
    data, ok := os.read_entire_file("./assets/config.ini", context.temp_allocator)
    //defer delete(data, context.allocator)

    if !ok {
        fmt.eprintln("Could not read the config file")
        return false
    }

    buffer := string(data)
    config_load_controls(buffer)

    return true
}

@(private = "file")
config_key_bind :: proc(key: Key, key_name: cstring) {
    scan_code := SDL.GetScancodeFromName(key_name)
    //defer delete(key_name)

    if scan_code == .UNKNOWN {
        fmt.eprintln("Invalid scan code when binding key: ", key_name)
        return
    }

    config_state.keybinds[key] = u8(scan_code)
}

@(private = "file") 
config_load_controls :: proc(config_buffer: string) {
    config_key_bind(.LEFT,     config_get_value(config_buffer, "Left"))
    config_key_bind(.RIGHT,    config_get_value(config_buffer, "Right"))
    config_key_bind(.UP,     config_get_value(config_buffer, "Up"))
    config_key_bind(.DOWN,    config_get_value(config_buffer, "Down"))
    config_key_bind(.ESCAPE,   config_get_value(config_buffer, "Escape"))
}

@(private = "file")
config_get_value :: proc(config_buffer: string, value: string) -> cstring {
    lines, ok := strings.split_lines_after(config_buffer, context.temp_allocator)
    //defer delete(lines)

    if ok != nil {
        fmt.eprintln("Error while processing the config buffer. ", ok)
        return nil
    }

    for line in lines {
        if strings.contains(line, value) {
            line_len := len(line)
            start_index := 0
            len := 0
            for i := 0; i < line_len; i += 1 {
                if line[i] == '=' {
                    start_index = i
                }

                if start_index != 0 && line[i] != '=' && line[i] != ' ' {
                    start_index = i
                    break
                }
            }

            for i:= start_index; i < line_len; i += 1 {
                if line[i] != '\n' && line[i] != '\r' {
                    len += 1
                }
            }

            result := strings.cut(line, start_index, len)
            return fmt.ctprintf(result)
        }
    }

    fmt.eprintln("Could not find config value: ", value)
    return nil
}