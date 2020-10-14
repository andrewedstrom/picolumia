
function _draw()
    cls()
    camera()

    if game_state == "menu" then
        draw_menu()
    else
        draw_hud()
        if drawing_combo_text and costatus(drawing_combo_text) != dead then
            coresume(drawing_combo_text)
        end

        doshake()
        draw_board()
    end

    local board_center = board_left+40
    if game_state == "gameover" then
        print_in_box("game over",board_center, 44)
        print_in_box("press \x97 to try again ",board_center, 99)
    elseif game_state == "won" then
        print_in_box("you win!!!",board_center, 44)
        print_in_box("press \x97 to play again ",board_center, 99)
    end
end

function draw_menu()
    -- halo
    pal(7,1)
    sspr(1,8,121,25,4,45)
    sspr(1,8,121,25,5,44)
    sspr(1,8,121,25,6,45)
    sspr(1,8,121,25,5,46)
    pal()

    -- real title
    sspr(1,8,121,25,5,45)

    centered_print("press \x97 to begin", 64, 103,7,1)

    if loading then
        fadepal(current_fade_perc)
        current_fade_perc+=fade_speed
    end
end

-- The board is organized with 1,1 as the bottom left corner
-- every other row is drawn shifted right by a half position
-- the diamond shape is made by setting the out-of-bounds spaces to "wall"
function draw_board()
    local shadow
    if player then
        shadow = player_quad_shadow()
    end

    for_all_tiles(function(y,x)
        local y_loc, x_loc = get_screen_position_for_block(y,x)
        if board[y][x] != wall then
            local sprite = board[y][x]

            if sprite == empty and display_shadow and shadow and shadow:is_in_shadow(y,x) and not currently_clearing_blocks() then
                -- switch block colors to block shadow colors
                pal()
                pal(12, 3)
                pal(8, 2)
                pal(7, 6)
                pal(10, 9)
                sprite = shadow:get_corresponding_sprite(y,x)
            end


            sspr(sprite,0,sprite_size,sprite_size,x_loc,y_loc)
            pal()
            setup_palette()
        end
    end)

    if display_shadow and shadow then
        shadow:draw_slide_indicator_arrow()
    end
    draw_board_outline()
end

function draw_board_outline()
    -- draw outline of board
    color(board_outline_color)
    local center_point_x=board_left+38
    local bottom_corner_y=bottom-28
    local upper_corner_y=bottom-79
    local bottom_point_y=bottom+5

    -- left side
    local left_side_line_x=board_left+5
    line(center_point_x, bottom_point_y, left_side_line_x, bottom_corner_y)
    line(left_side_line_x, upper_corner_y)
    line(center_point_x, bottom-board_height*piece_height-4)

    -- right side
    local right_side_line_x=board_left+board_width*piece_width+8
    line(center_point_x+1, bottom-board_height*piece_height-4, right_side_line_x, upper_corner_y)
    line(right_side_line_x, bottom_corner_y)
    line(center_point_x+1, bottom_point_y)
end

function draw_hud()
    local right_side_x=board_left+84
    local y_loc=8

    color(7)
    print("time",right_side_x, y_loc)
    print(display_time(), right_side_x, y_loc+8)

    print("level", right_side_x, y_loc+24)
    print(level.."/15", right_side_x, y_loc+32)

    print("cleared",right_side_x,y_loc+48)
    print(cleared, right_side_x,y_loc+56)

    print("score", right_side_x, y_loc+72)
    print(score, right_side_x, y_loc+80)

    local next_quad_y = y_loc+96
    local next_quad_x = right_side_x +piece_width/2
    sspr(next_quad.p3,0,sprite_size,sprite_size,next_quad_x,next_quad_y)
    sspr(next_quad.p2,0,sprite_size,sprite_size,next_quad_x+piece_width/2,next_quad_y+piece_height)
    sspr(next_quad.p1,0,sprite_size,sprite_size,next_quad_x-piece_width/2,next_quad_y+piece_height)
    sspr(next_quad.p0,0,sprite_size,sprite_size,next_quad_x,next_quad_y+piece_height*2)
end

function draw_combo_text()
    local x_loc=board_left-5
    local y_loc=8
    local message = combo_size.."x combo!"

    local i
    for i=1,20 do
        if i % 5 == 0 then
            y_loc -= 1
        end
        print(message,x_loc,y_loc,11)
        yield()
    end
end

function get_screen_position_for_block(y,x)
    local x_loc=x*piece_width + board_left
    if is_odd(y) then
        x_loc += piece_width/2
    end
    local y_loc=bottom-y*piece_height
    return y_loc, x_loc
end

-- return time elapsed in format mm:ss
function display_time()
    local minutes = flr(seconds_elapsed / 60)
    local seconds_remainder = seconds_elapsed % 60
    local display_minutes = tostr(minutes)
    if #display_minutes < 2 then
        display_minutes = "0" .. display_minutes
    end
    local display_seconds = tostr(seconds_remainder)
    if #display_seconds < 2 then
        display_seconds = "0" .. display_seconds
    end

    return display_minutes .. ":" .. display_seconds
end