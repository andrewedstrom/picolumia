-->8
-- fancy printing

function print_in_box(message, x, y)
    local pico8_letter_width = 4
    local message_width_px = #message * pico8_letter_width
    local box_left = x - message_width_px / 2 - pico8_letter_width
    local box_right = x + message_width_px / 2 + 2
    local box_top = y - pico8_letter_width
    local box_bottom = y + pico8_letter_width * 2
    local box_color = 6

    rectfill(box_left + 1, box_top + 1, box_right - 1, box_bottom - 1, box_color)
    rectfill(box_left, box_top + 2, box_right, box_bottom - 2, box_color)

    print(message, x - message_width_px / 2, y, 1)

end

function centered_print(text, x, y, col, outline_col)
    outlined_print(text, x - #text * 2, y, col, outline_col)
end

function outlined_print(text, x, y, col, outline_col)
    print(text, x - 1, y, outline_col)
    print(text, x + 1, y, outline_col)
    print(text, x, y - 1, outline_col)
    print(text, x, y + 1, outline_col)

    print(text, x, y, col)
end
