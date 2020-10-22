-->8
-- juice

function doshake()
    local x_pos = flr(x_shift)
    if x_shift < 0 then
        x_pos = ceil(x_shift)
    end
    camera(x_pos,y_shift)
    x_shift *= shimmy_degredation_rate
    y_shift *= shimmy_degredation_rate
    if abs(x_shift) < minimum_shimmy_threshold then
        x_shift = 0
    end
    if abs(y_shift) < minimum_shimmy_threshold then
        y_shift = 0
    end
end

-- whole_screen = 1 means swap palette for whole existing screen
-- whole_screen = 0 means just change the draw palette
function fadepal(_perc, whole_screen)
    -- this function sets the
    -- color palette so everything
    -- you draw afterwards will
    -- appear darker
    -- it accepts a number from
    -- 0 means normal
    -- 1 is completely black
    -- this function has been
    -- adapted from the jelpi.p8
    -- demo
    local p = flr(mid(0, _perc, 1) * 100)

    local kmax, col, dpal, j, k

    -- this is a table to do the
    -- palette shifiting. it tells
    -- what number changes into
    -- what when it gets darker
    -- so number
    -- 15 becomes 14
    -- 14 becomes 13
    -- 13 becomes 1
    -- 12 becomes 3
    -- etc...
    dpal = {0, 1, 1, 2, 1, 13, 6, 4, 4, 9, 3, 13, 1, 13, 14}

    for j = 1, 11 do -- should go to 15 but we never need to fade colors above 11
        col = j

        -- now calculate how many
        -- times we want to fade the
        -- color.
        -- this is a messy formula
        -- and not exact science.
        -- but basically when kmax
        -- reaches 5 every color gets
        -- turned black.
        kmax = (p + (j * 1.46)) / 22

        -- now we send the color
        -- through our table kmax
        -- times to derive the final
        -- color
        for k = 1, kmax do col = dpal[col] end

        -- finally, we change the
        -- palette
        pal(j, col, whole_screen)
    end
end


function particles_for_block_clear(y, x, block_col)
    -- at first just spawn one
    local x_loc
    local y_loc
    y_loc, x_loc = get_screen_position_for_block(y,x)
    local i
    local number_of_particles = 10 + 2 * min(level, 10)

    for i = 1, number_of_particles do
        -- determine particle color
        local col = 7
        if i % 7 ~= 0 or block_col == white_block then
            -- most particles are white
            col = 7
        elseif block_col == blue_block then
            col = 12
        elseif block_col == red_block then
            col = 8
        elseif block_col == yellow_block then
            col = 10
        end

        -- create particle
        add(particles, {
            x=x_loc,
            y=y_loc,
            r=rnd(2),
            color=col,
            mult=rnd(1)/300,
            ttl=40+rnd(30),
            fade_perc=0,
            starting_theta=rnd(1),
            update=function(self)
                self.r = self.r + 1.8
                self.ttl = self.ttl - 1
                if self.ttl < 20 then
                    self.fade_perc = self.fade_perc + fade_speed
                end
            end,
            draw=function(self)
                theta = self.r * self.mult + self.starting_theta
                local spiral_x = self.r * cos(theta)
                local spiral_y = self.r * sin(theta)
                local x_coord = self.x + spiral_x
                local y_coord = self.y + spiral_y

                if x_coord > 128 or x_coord < 0 or y_coord > 128 or y_coord < 0 then
                    self.ttl = -1
                else
                    if self.fade_perc > 0 then
                        fadepal(self.fade_perc, 0)
                    end

                    pset(x_coord, y_coord, self.color)

                    if self.fade_perc > 0 then
                        setup_palette()
                    end
                end
            end,
            is_expired=function(self)
                return self.ttl < 0 or self.fade_perc > 1.1
            end
        })
    end
end