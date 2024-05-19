local utils = require 'cmp_rime.utils'

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
  -- return [[.*]]
  return [[\%([a-zA-Z]\)*]]
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
            M.server = 'exist'
            local msg = string.format("--- SERVER START ERROR ---\n%s", cmd)
            return vim.notify(msg, vim.log.levels.ERROR, {title = 'Rime'})
        else
            M.server = server
        end
    end
    local serve_address = opts.rime_server_address

    local host = 'http://' .. serve_address
    utils.rpc(host, '/rpc/get_candidates', {
        key_sequence = keys,
        max_candidates = opts.max_candidates,
        shared_data_dir = opts.shared_data_dir,
        user_data_dir = opts.user_data_dir,
    }, function (result)
            -- vim.notify(vim.inspect(result.candidates))
            assert(type(result.candidates) == 'table', vim.inspect(result))
            local items = {}
            for i, candidate in ipairs(result.candidates) do
                items[#items + 1] = {
                    label = candidate.text .. candidate.comment,
                    filterText = keys,
                    sortText = "~" .. tostring(i + 100000),
                    kind = 0,
                    textEdit = {
                        newText = candidate.text,
                        range = {
                            start = {
                                line = cursor.row - 1,
                                character = cursor.col - utils.utf8len(keys),
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
        end)
end

-- function M.complete(self, request, callback)
-- end

return M
