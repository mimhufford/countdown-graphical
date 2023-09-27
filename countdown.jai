margin :: 75;
width  :: 96*5 + margin*2;
height :: 128  + margin*2;
particles_per_digit :: 500;

particles : [5 * particles_per_digit]Particle;
digits : [11]Bitmap;
countdown := 180.0;
end_effect := End_Effect.EXPLODE;
window : Window_Type;
dt : float;

main :: () {
    load_bitmaps();
    window = create_window(width, height, "Starting soon!");
    set_render_target(window);
    
    last_time := current_time_monotonic();

    quit := false;
    while !quit {
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

        {   // calcuate dt and update countdown
            now := current_time_monotonic();
            dt = 0.000000001 * to_nanoseconds(now - last_time);
            last_time = now;

            countdown -= dt;
            countdown = max(countdown, 0);
        }

        clear_render_target(0.1, 0.1, 0.1, 1);
        set_shader_for_color();
        if countdown update_and_render_particles_during_countdown();
        else         update_and_render_particles_after_time_is_up();
        swap_buffers(window);
        sleep_milliseconds(10);
        reset_temporary_storage();
    }
}

update_and_render_particles_during_countdown :: () {
    assert(countdown >= 0);
    minutes := cast(int)(countdown / 60);
    seconds := cast(int)(countdown - minutes * 60);
    m1, m2 := minutes / 10, minutes % 10;
    s1, s2 := seconds / 10, seconds % 10;

    mouse_x, mouse_y := get_mouse_pointer_position(window, true);

    for * p, index: particles {
        digit, column : int;
        if index < particles_per_digit*5 { digit = s2; column = 4; }
        if index < particles_per_digit*4 { digit = s1; column = 3; }
        if index < particles_per_digit*3 { digit = 10; column = 2; }
        if index < particles_per_digit*2 { digit = m2; column = 1; }
        if index < particles_per_digit*1 { digit = m1; column = 0; }

        if p.life <= 0 {
            while true {
                p.position.x = random_get_zero_to_one() * (digits[digit].width - 1);
                p.position.y = random_get_zero_to_one() * (digits[digit].height - 1);
                index := (cast(int)p.position.y * digits[digit].width + cast(int)p.position.x) * get_image_bytes_per_texel(digits[digit].format);
                if digits[digit].data[index] > 0 break;
            }
            p.position.y = digits[digit].height - p.position.y + margin;
            p.position.x += 96*column + margin;
            p.radius = random_get_within_range(3, 6);
            p.colour = .{random_get_zero_to_one(), random_get_zero_to_one(), random_get_zero_to_one(), 1};
            if countdown <= 1 { p.colour.y = p.colour.x; p.colour.z = p.colour.x; }
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

update_and_render_particles_after_time_is_up :: () {
    if #complete end_effect == {
        case .EXPLODE; update_and_render_explode_effect();
        case .BOUNCE;  update_and_render_bounce_effect();
    }
}

update_and_render_explode_effect :: () {
    for * p, index: particles {
        p.position += p.velocity * dt * 100;

        jitter :: 2.0;
        p.position.x += random_get_within_range(-jitter, jitter);
        p.position.y += random_get_within_range(-jitter, jitter);

        p.colour = .{random_get_zero_to_one(), random_get_zero_to_one(), random_get_zero_to_one(), 1};

        p.radius = max(0.5, p.radius - dt);
        if p.radius <= 0.5 continue;

        render_particle(p);
    }
}

update_and_render_bounce_effect :: () {
    for * p, index: particles {
        p.velocity.y -= 5 * dt;
        p.position += p.velocity * dt * 40;
        if p.position.y < 0 p.velocity.y *= random_get_within_range(-1.0, -0.6);

        p.radius = max(0.5, p.radius - dt * 0.7);
        if p.radius <= 0.5 continue;

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

End_Effect :: enum {
    EXPLODE;
    BOUNCE;
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
    bitmap_load_from_memory(*digits[10], image_c_data);
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