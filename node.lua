-- vim: set fileencoding=latin1:

gl.setup(1920, 1080)

-- give this node the alias 'display'
node.alias "display"

util.no_globals()

local Display = function(display_cols, display_rows)
    local t = resource.load_image "letters.png"
    local mapping = ' abcdefghijklmnopqrstuvwxyzäöü0123456789@#-.,:?!()'

    local function make_mapping(cols, rows, tw, th)
        local chars = {}
        for i = 0, #mapping * 5 - 1 do
            local cw = tw/cols
            local ch = th/rows
            local x =           (i % cols) * cw
            local y = math.floor(i / cols) * ch
            chars[#chars+1] = function(x1, y1, x2, y2)
                t:draw(x1, y1, x2, y2, 1.0, x/tw, y/th, (x+cw)/tw, (y+ch)/th)
            end
        end
        return chars
    end

    local charmap = make_mapping(20, 13, 2000, 1950)

    local row = function(rowsize)
        local function mkzeros(n)
            local out = {}
            for i = 1, n do 
                out[#out+1] = 0
            end
            return out
        end

        local current = mkzeros(rowsize)
        local target  = mkzeros(rowsize)
        local function set(value)
            assert(#value <= rowsize)
            value = value .. string.rep(" ", rowsize-#value)
            for i = 1, rowsize do
                local char = string.sub(value,i,i):lower()
                local pos = string.find(mapping, char, 1, true)
                if not pos then
                    pos = 1 -- character not found
                end
                target[i] = (pos-1) * 5
            end
        end

        local function tick()
            for i = 1, rowsize do
                if current[i] ~= target[i] then
                    current[i] = current[i] + 1
                    if current[i] >= #mapping * 5 then
                        current[i] = 0
                    end
                end
            end
        end

        local function draw(y, charh)
            local charw = WIDTH / rowsize
            local margin = 2
            for i = 1, rowsize do
                charmap[current[i]+1]((i-1)*charw+margin, y+margin, i*charw-margin, y+charh-margin)
            end
        end

        return {
            set = set;
            tick = tick;
            draw = draw;
        }
    end

    local rows = {}
    for i = 1, display_rows do
        rows[#rows+1] = row(display_cols)
    end

    local current = 1
    local function append(line)
        line = line:sub(1, display_cols)
        rows[current].set(line)
        current = current + 1
        if current > #rows then
            current = 1
        end
    end

    local function go_up()
        current = 1
    end

    local function clear()
        for i = 1, display_rows do
            rows[i].set("")
        end
        go_up()
    end

    local function draw()
        local charh = HEIGHT / display_rows
        for i = 1, display_rows do
            rows[i].tick()
            rows[i].draw((i-1)*charh, charh)
        end
    end

    return {
        append = append;
        clear = clear;
        go_up = go_up;
        draw = draw;
        is_size = function(w, h)
            return display_cols == w and display_rows == h
        end;
    }
end

local display

local sessions = {}

node.event("connect", function(client, path)
    sessions[client] = {
        atomic = path == "atomic",
        lines = {},
    }
end)

node.event("input", function(line, client)
    local session = sessions[client]
    if session.atomic then
        session.lines[#session.lines+1] = line
    else
        display.append(line)
    end
end)

node.event("disconnect", function(client)
    local session = sessions[client]
    if session.atomic then
        display.clear()
        for _, line in ipairs(session.lines) do
            display.append(line)
        end
    end
end)

util.json_watch("config.json", function(config)
    local width, height = unpack(config.size)
    local reinit = not display or not display.is_size(width, height)
    if reinit then
        display = Display(width, height)
    else
        display.clear()
    end

    -- set initial output
    for line in (config.text .. "\n"):gmatch("(.-)\n") do
        display.append(line)
    end
end)
    
function node.render()
    display.draw()
end
