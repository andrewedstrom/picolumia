-->8
-- configuration options

-- shadow
function turn_on_shadow()
    display_shadow = true
    menuitem(1, "hide shadow", turn_off_shadow)
end

function turn_off_shadow()
    display_shadow = false
    menuitem(1, "show shadow", turn_on_shadow)
end

-- inverse rotation buttons (for mobile players)
function standard_rotation_mode()
    swap_rotation_buttons = false
    menuitem(2, "inverse rotation", inverse_rotation_mode)
end

function inverse_rotation_mode()
    swap_rotation_buttons = true
    menuitem(2, "normal rotation", standard_rotation_mode)
end

-- millisecond display (for speedrunners)
function turn_on_millisecond_display()
    display_milliseconds = true
    menuitem(3, "hide millis", turn_off_millisecond_display)
end

function turn_off_millisecond_display()
    display_milliseconds = false
    menuitem(3, "show millis", turn_on_millisecond_display)
end