SCALE  :: 45;
width  := 15 * SCALE;
height := 5 * SCALE;
particles_per_digit :: 500;
particles : [6 * particles_per_digit]Particle;
digits : [10]Bitmap;
code := s64.[0,0,0,0,0,0];
window : Window_Type;
dt : float;
quit := false;
code_index_to_update := 0;

main :: () {
    load_bitmaps();
    window = create_window(width, height, "Register Code");
    set_render_target(window);

    args := get_command_line_arguments();
    if args.count > 1 && args[1].count == 6 {
        for args[1] code[it_index] = it - #char "0";
    }
    
    last_time := current_time_monotonic();

    while !quit {
        update_window_events();

        for get_window_resizes() {
            if it.window != window continue;
            update_window(window);
            width = it.width;
            height = it.height;
        }

        for events_this_frame {
            if it.type == .QUIT          quit = true;
            if it.key_code == .ESCAPE    quit = true;
            if it.type != .KEYBOARD      continue;
            if it.key_pressed == 0       continue;
            if it.repeat                 continue;
            if it.key_code == .BACKSPACE reset_code();
            process_digit(it.key_code);
        }

        {
            now := current_time_monotonic();
            dt = 0.000000001 * to_nanoseconds(now - last_time);
            last_time = now;
        }

        clear_render_target(0.1, 0.1, 0.1, 1);
        set_shader_for_color();
        update_and_render_particles();
        swap_buffers(window);
        sleep_milliseconds(10);
        reset_temporary_storage();
    }
}

reset_code :: () {
    for * code it.* = 0;
    code_index_to_update = 0;
}

process_digit :: (key: Key_Code) {
    if key < #char "0" return;
    if key > #char "9" return;
    code[code_index_to_update] = cast(u8, key) - #char "0";
    code_index_to_update += 1;
    code_index_to_update %= code.count;
}

update_and_render_particles:: () {
    digit_width := digits[0].width;
    digit_height := digits[0].height;
    code_width := digit_width * code.count;
    left_padding := width / 2 - code_width / 2;
    top_padding := height / 2 - digit_height / 2;
    mouse_x, mouse_y := get_mouse_pointer_position(window, true);

    for * p, index: particles {
        digit, column : int;
        if index < particles_per_digit*6 { digit = code[5]; column = 5; }
        if index < particles_per_digit*5 { digit = code[4]; column = 4; }
        if index < particles_per_digit*4 { digit = code[3]; column = 3; }
        if index < particles_per_digit*3 { digit = code[2]; column = 2; }
        if index < particles_per_digit*2 { digit = code[1]; column = 1; }
        if index < particles_per_digit*1 { digit = code[0]; column = 0; }

        if p.life <= 0 {
            while true {
                p.position.x = random_get_zero_to_one() * (digit_width-1);
                p.position.y = random_get_zero_to_one() * (digit_height-1);
                index := (cast(int)p.position.y * digit_width + cast(int)p.position.x) * get_image_bytes_per_texel(digits[digit].format);
                if digits[digit].data[index] > 0 break;
            }
            p.position.y = top_padding + digit_height - p.position.y;
            p.position.x += left_padding + (digit_width * column);
            p.radius = random_get_within_range(3, 6);
            p.colour = .{random_get_zero_to_one(), random_get_zero_to_one(), random_get_zero_to_one(), 1};
            p.life = random_get_within_range(1, 2);
        }

        jitter :: 2.0;
        p.velocity.x = random_get_within_range(-jitter, jitter);
        p.velocity.y = random_get_within_range(-jitter, jitter);

        p.position += p.velocity;

        dx := mouse_x - p.position.x;
        dy := mouse_y - p.position.y;
        if dx*dx + dy*dy < 400 {
            p.position.x -= dx;
            p.position.y -= dy;
        }

        p.life -= dt*3;
        p.radius -= dt*5;

        render_particle(p);
    }
}

render_particle :: (using particle: *Particle) {
    left   := position.x - radius;
    right  := position.x + radius;
    top    := position.y + radius;
    bottom := position.y - radius;
    immediate_quad(left, bottom, right, top, colour);
}

Particle :: struct {
    position : Vector2;
    velocity : Vector2;
    radius   : float;
    colour   : Vector4;
    life     : float;
}

load_bitmaps :: () {
    bitmap_load_from_memory(*digits[ 0], image_0_data);
    bitmap_load_from_memory(*digits[ 1], image_1_data);
    bitmap_load_from_memory(*digits[ 2], image_2_data);
    bitmap_load_from_memory(*digits[ 3], image_3_data);
    bitmap_load_from_memory(*digits[ 4], image_4_data);
    bitmap_load_from_memory(*digits[ 5], image_5_data);
    bitmap_load_from_memory(*digits[ 6], image_6_data);
    bitmap_load_from_memory(*digits[ 7], image_7_data);
    bitmap_load_from_memory(*digits[ 8], image_8_data);
    bitmap_load_from_memory(*digits[ 9], image_9_data);
}

image_0_data :: #run add_global_data(xx read_entire_file("images/0.png"), .READ_ONLY);
image_1_data :: #run add_global_data(xx read_entire_file("images/1.png"), .READ_ONLY);
image_2_data :: #run add_global_data(xx read_entire_file("images/2.png"), .READ_ONLY);
image_3_data :: #run add_global_data(xx read_entire_file("images/3.png"), .READ_ONLY);
image_4_data :: #run add_global_data(xx read_entire_file("images/4.png"), .READ_ONLY);
image_5_data :: #run add_global_data(xx read_entire_file("images/5.png"), .READ_ONLY);
image_6_data :: #run add_global_data(xx read_entire_file("images/6.png"), .READ_ONLY);
image_7_data :: #run add_global_data(xx read_entire_file("images/7.png"), .READ_ONLY);
image_8_data :: #run add_global_data(xx read_entire_file("images/8.png"), .READ_ONLY);
image_9_data :: #run add_global_data(xx read_entire_file("images/9.png"), .READ_ONLY);

#run {
    #if OS == .WINDOWS {
        #import "Windows_Resources";
        disable_runtime_console();
    }
}

#import "File";
#import "Math";
#import "Simp";
#import "Basic";
#import "Input";
#import "Random";
#import "Compiler";
#import "Window_Creation";