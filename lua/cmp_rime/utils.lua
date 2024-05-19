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

return M
