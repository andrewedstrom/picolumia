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