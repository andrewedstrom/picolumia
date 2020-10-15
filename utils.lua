function setup_palette()
    _pal={0,129,136,140,1,5,6,7,8,135,10,131,12,13,133,134}
    for i,c in pairs(_pal) do
        pal(i-1,c,1)
    end
end

function currently_clearing_blocks()
    return blocks_clearing and costatus(blocks_clearing) != 'dead'
end

function for_all_tiles(callback)
    for y = 1, board_height do
        for x = 1, board_width do
            if board[y][x] != wall then
                callback(y, x)
            end
        end
    end
end

function is_odd(num)
    return num % 2 != 0
end

function get_screen_position_for_block(y,x)
    local x_loc=x*piece_width + board_left
    if is_odd(y) then
        x_loc += piece_width/2
    end
    local y_loc=bottom-y*piece_height
    return y_loc, x_loc
end