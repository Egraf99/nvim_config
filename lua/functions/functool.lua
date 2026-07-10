local M = {}

function M.map(tbl, func)
    local new_tbl = {}
    for v in tbl do
        table.insert(new_tbl, 1, func(v))
    end
    return new_tbl
end

function M.all(tbl)
    local result = true
    for _, v in ipairs(tbl) do
        result = v and result
    end
    return result
end

function M.any(tbl)
    local result = false
    for _, v in ipairs(tbl) do
        result = v or result
    end
    return result
end



local charset = {}  do -- [0-9a-zA-Z]
    for c = 48, 57  do table.insert(charset, string.char(c)) end
    for c = 65, 90  do table.insert(charset, string.char(c)) end
    for c = 97, 122 do table.insert(charset, string.char(c)) end
end

function M.randomString(length)
    if not length or length <= 0 then return '' end
    math.randomseed(os.clock()^5)
    return M.randomString(length - 1) .. charset[math.random(1, #charset)]
end



return M
