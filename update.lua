function _update()
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
