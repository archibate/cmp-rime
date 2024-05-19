local curl = require 'plenary.curl'

local M = {}

local defaults = {
    rime_server_cmd = './rime_server',
    rime_server_address = '127.0.0.1:47992',
    shared_data_dir = '/usr/share/rime-data',
    user_data_dir = vim.fn.getenv('HOME') .. '/.local/share/cmp-rime',
    max_candidates = 10,
}

function M.new()
  return setmetatable({}, { __index = M })
end

function M.get_keyword_pattern()
  -- return [[\%([a-zA-Z%.,%\!?;%(%)]\)*]]
  return [[\%([a-zA-Z]\)*]]
end

local function utf8len(s)
    local len = 0
    for i = 1, #s do
        local c = string.byte(s, i)
        if c < 0x80 or c >= 0xC0 then
            len = len + 1
        end
    end
    return len
end

function M.complete(_, request, callback)
    local opts = vim.tbl_deep_extend('keep', request.option, defaults)
    vim.validate({
        rime_server_cmd = { opts.rime_server_cmd, 'string' },
        rime_server_address = { opts.rime_server_address, 'string' },
        shared_data_dir = { opts.shared_data_dir, 'string' },
        user_data_dir = { opts.user_data_dir, 'string' },
        max_candidates = { opts.max_candidates, 'number' },
    })
    -- if request.option.enable then
    -- end

    local keys = string.sub(request.context.cursor_before_line, request.offset)
    local cursor = request.context.cursor

    -- vim.lsp.start({
    --     name = 'cmp-rime',
    --     cmd = {'sh', '-c', cmd},
    -- })
    if not M.server then
        local thisdir = debug.getinfo(1).source:sub(2):match("(.*)/") .. "/../.."
        local cmd = "cd '" .. thisdir .. "' && " .. opts.rime_server_cmd .. " " .. opts.rime_server_address .. " >/dev/null 2>&1"
        local server = io.popen(cmd, 'r')
        if not server then
            -- M.server = 'exist'
            local msg = string.format("--- SERVER START ERROR %d ---\n%s", cmd)
            return vim.notify(msg, vim.log.levels.ERROR, {title = 'Rime'})
        else
            M.server = server
        end
    else
    end

    local serve_address = opts.rime_server_address
    -- local serve_address = nil
    -- for line in M.server:lines() do
    --     -- if line starts with "listening at: "
    --     if line:find('listening at: ') then
    --         -- extract the ip address in "listening at: 127.0.0.1:1234"
    --         local address = line:match('listening at: ([^:]+):')
    --         if not address then
    --             local msg = string.format("--- SERVER ERROR ---\n%s", line)
    --             return vim.notify(msg, vim.log.levels.ERROR, {title = 'Rime'})
    --         end
    --         serve_address = address
    --         break
    --     end
    -- end
    -- if not serve_address then
    --     local msg = string.format("--- SERVER ERROR ---\nNOT STARTED")
    --     return vim.notify(msg, vim.log.levels.ERROR, {title = 'Rime'})
    -- end

    local host = 'http://' .. serve_address
    local success, _ = pcall(curl.post, host .. '/rpc/get_candidates', {
        headers = {
            content_type = 'application/json',
        },
        body = vim.fn.json_encode{
            key_sequence = keys,
            max_candidates = opts.max_candidates,
            shared_data_dir = opts.shared_data_dir,
            user_data_dir = opts.user_data_dir,
        },
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

            assert(type(result.candidates) == 'table', vim.inspect(result))
            local items = {}
            for i, candidate in ipairs(result.candidates) do
                items[#items + 1] = {
                    label = candidate.text,
                    filterText = keys,
                    sortText = "~" .. tostring(i + 100000),
                    kind = 0,
                    textEdit = {
                        newText = candidate.text,
                        range = {
                            start = {
                                line = cursor.row - 1,
                                character = cursor.col - utf8len(keys),
                            },
                            ['end'] = {
                                line = cursor.row - 1,
                                character = cursor.col - 1,
                            },
                        },
                    }
                }
            end
            callback({
                items = items,
                isIncomplete = true,
            })
        end),
    })
    if not success then
        local msg = string.format("--- CURL ERROR ---\n")
        return vim.notify(msg, vim.log.levels.ERROR, {title = 'Rime'})
    end
end

-- function M.complete(self, request, callback)
-- end

return M
