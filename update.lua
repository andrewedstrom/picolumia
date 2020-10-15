function _update()
    local p
    for p in all(particles) do
        p:update()
        if p:is_expired() then
            del(particles, p)
        end
    end
    if game_state == "menu" or game_state == "gameover" or game_state == "won" then
        update_menu()
    elseif game_state == "playing" then
        update_game()
    end
end


function update_game()
    update_timers()

    if currently_clearing_blocks() then
        coresume(blocks_clearing)
    elseif hard_dropping then
        move_down()
    else
        if speed_timer >= (speed - level) then
            tick()
            speed_timer = 0
        end
        handle_input()
    end
end

function update_timers()
    speed_timer += 1
    seconds_timer += 1

    if seconds_timer == 30 then
        seconds_elapsed += 1
        seconds_timer = 0
    end
end

function update_menu()
    if loading and current_fade_perc > 1.5 then
        start_game()
        loading=false
    elseif btn(4) or btn(5) then
        music(7)
        loading=true
    end
end

function tick()
    move_down()
end

function handle_input()
    local just_moved=false
    if btnp(0) then
        just_moved=move_left()
        x_shift=shimmy_coefficient
    elseif btnp(1) then
        just_moved=move_right()
        x_shift=-shimmy_coefficient
    elseif btn(3) then
        hard_dropping=true
        move_down()
        y_shift-=shimmy_coefficient
    end
    if just_moved then
        move_sound()
    end

    if btnp(4) then
        rotate_counter_clockwise()
        move_sound()
    elseif btnp(5) then
        rotate_clockwise()
        move_sound()
    end
end