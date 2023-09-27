main :: () {
    margin :: 75;
    width :: 96*5 + margin*2;
    height :: 128 + margin*2;

    particles_per_digit :: 500;
    particles : [5 * particles_per_digit]Particle;

    digits : [11]Bitmap;
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
    bitmap_load_from_memory(*digits[10], image_c_data);

    window := create_window(width, height, "Starting soon!");
    set_render_target(window);
    
    last_time := current_time_monotonic();

    countdown := 180.0;

    quit := false;
    while !quit {
        // calculate dt
        now := current_time_monotonic();
        dt := 0.000000001 * to_nanoseconds(now - last_time);
        last_time = now;

        // calculate digits to display
        countdown -= dt;
        countdown = max(countdown, 0);
        minutes := cast(int)(countdown / 60);
        seconds := cast(int)(countdown - minutes * 60);
        m1 := minutes / 10;
        m2 := minutes % 10;
        s1 := seconds / 10;
        s2 := seconds % 10;
        
        update_window_events();

        for events_this_frame {
            if it.type == .QUIT quit = true;
            if it.type != .KEYBOARD continue;
            if it.key_pressed == 0  continue;
            if it.repeat            continue;
            if it.key_code == .ESCAPE      quit = true;
            if it.key_code == .ARROW_RIGHT countdown += 60;
            if it.key_code == .ARROW_LEFT  countdown -= 60;
            if it.key_code == .ARROW_UP    countdown += 10;
            if it.key_code == .ARROW_DOWN  countdown -= 10;
        }

        clear_render_target(0.1, 0.1, 0.1, 1);
        set_shader_for_color();

        mouse_x, mouse_y := get_mouse_pointer_position(window, true);

        update_particles :: (first_index: int, digit: int, column: int) #expand {
            for first_index..first_index + particles_per_digit-1 {
                p := *particles[it];
                if p.life <= 0 {
                    while true {
                        p.x = random_get_zero_to_one() * (digits[digit].width - 1);
                        p.y = random_get_zero_to_one() * (digits[digit].height - 1);
                        index := (cast(int)p.y * digits[digit].width + cast(int)p.x) * get_image_bytes_per_texel(digits[digit].format);
                        if digits[digit].data[index] > 0 break;
                    }
                    p.y = digits[digit].height - p.y + margin;
                    p.x += 96*column + margin;
                    p.radius = random_get_within_range(3, 6);
                    p.colour = .{random_get_zero_to_one(), random_get_zero_to_one(), random_get_zero_to_one(), 1};
                    if countdown <= 1 { p.colour.y = p.colour.x; p.colour.z = p.colour.x; }
                    p.life = random_get_within_range(1, 2);
                }

                jitter :: 2.0;
                p.x += random_get_within_range(-jitter, jitter);
                p.y += random_get_within_range(-jitter, jitter);

                dx := mouse_x - p.x;
                dy := mouse_y - p.y;
                if dx*dx + dy*dy < 400 {
                    p.x -= dx;
                    p.y -= dy;
                }

                p.life -= dt*3;
                p.radius -= dt*5;
                immediate_quad(p.x - p.radius, p.y - p.radius, p.x + p.radius, p.y + p.radius, p.colour);
            }
        }

        update_particles(particles_per_digit*0, m1, 0);
        update_particles(particles_per_digit*1, m2, 1);
        update_particles(particles_per_digit*2, 10, 2);
        update_particles(particles_per_digit*3, s1, 3);
        update_particles(particles_per_digit*4, s2, 4);

        swap_buffers(window);
        sleep_milliseconds(10);
        reset_temporary_storage();
    }
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
image_c_data :: #run add_global_data(xx read_entire_file("images/c.png"), .READ_ONLY);

Particle :: struct {
    x : float;
    y : float;
    radius : float;
    colour : Vector4;
    life : float;
}

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