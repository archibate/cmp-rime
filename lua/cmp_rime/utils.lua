local curl = require 'plenary.curl'

local M = {}

function M.utf8len(s)
    local len = 0
    for i = 1, #s do
        local c = string.byte(s, i)
        if c < 0x80 or c >= 0xC0 then
            len = len + 1
        end
    end
    return len
end

function M.rpc(host, uri, body, callback)
    local success, _ = pcall(curl.post, host .. uri, {
        headers = {
            content_type = 'application/json',
        },
        body = vim.fn.json_encode(body),
        on_error = vim.schedule_wrap(function (res)
            local msg = string.format("--- CURL ERROR %d ---\n%s", res.exit, res.message)
            return vim.notify(msg, vim.log.levels.ERROR, {title = 'Rime'})
        end),
        callback = vim.schedule_wrap(function (res)
            if res.status ~= 200 then
                local msg = string.format("--- HTTP ERROR %d ---\n%s", res.status, res.body)
                return vim.notify(msg, vim.log.levels.ERROR, {title = 'Rime'})
            end
            local success, result = pcall(vim.fn.json_decode, res.body)
            if not success then
                local msg = string.format("--- JSON DECODE FAILURE ---\n%s", res.body)
                return vim.notify(msg, vim.log.levels.ERROR, {title = 'Rime'})
            end
            callback(result)
        end),
    })
    if not success then
        local msg = string.format("--- CURL ERROR ---\n")
        return vim.notify(msg, vim.log.levels.ERROR, {title = 'Rime'})
    end
end

function M.detect_chinese_english(line)
    if not line then
        return 0, 0
    end
    local chinese = 0
    local english = 0
    for i = 1, #line do
        local c = line:byte(i)
        if 65 <= c and c <= 90 or 97 <= c and c <= 122 then
            english = english + 1
        elseif 228 <= c and c <= 233 then -- U+4E00-U9FFF (一~鿿)
            chinese = chinese + 1
        else
        end
    end
    -- print(line, english, chinese)
    return chinese, english
end

function M.remove_prefix(str, prefix)
    if str:sub(1, #prefix) == prefix then
        return str:sub(#prefix + 1), true
    else
        return str, false
    end
end

function M.detect_context(keys, cursor, context_range, force_enable_prefix)
    local linecount = vim.api.nvim_buf_line_count(0)
    local line = vim.api.nvim_buf_get_lines(0, cursor.row - 1, cursor.row, false)[1]
    local chinese, english = M.detect_chinese_english(line)
    local same_line = true
    if chinese == 0 then
        same_line = false
        local lines = vim.api.nvim_buf_get_lines(0, math.max(0, cursor.row - 1 - context_range), math.min(linecount, cursor.row + context_range), false)
        for _, l in ipairs(lines) do
            local c, e = M.detect_chinese_english(l)
            chinese = chinese + c
            english = english + e
        end
    end
    local detected = chinese > 0
    if not detected and force_enable_prefix ~= '' then
        keys, detected = M.remove_prefix(keys, force_enable_prefix)
        if not detected and line:find(force_enable_prefix) then
        detected = true
        same_line = true
        end
    end
    return keys, detected, detected and same_line
end

return M
