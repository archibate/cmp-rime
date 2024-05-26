local M = {}

local utils = require 'cmp-rime.utils'
local indexTab = {'①', '②', '③', '④', '⑤', '⑥', '⑦', '⑧', '⑨', '⑩', '⑪', '⑫', '⑬', '⑭', '⑮', '⑯', '⑰', '⑱', '⑲', '⑳', '㉑', '㉒', '㉓', '㉔', '㉕', '㉖', '㉗', '㉘', '㉙', '㉚', '㉛', '㉜'}

local defaults = {
    enable = 'auto',
    preselect_number = true,
    preselect_first = true,
    label_with_index = 'none',
    context_range = 2,
    context_threshold = 1,
    not_same_line_penalty = 1,
    force_enable_prefix = 'rime',
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
    if M.disabled then
        return [[]]
    end
    return [[\%([a-zA-Z]\)*[0-9]*]]
end

function M.complete(_, request, callback)
    local opts = vim.tbl_deep_extend('keep', request.option, defaults)
    vim.validate({
        enable = { opts.enable, 'string' },
        preselect_number = { opts.preselect_number, 'boolean' },
        preselect_first = { opts.preselect_first, 'boolean' },
        label_with_index = { opts.label_with_index, 'string' },
        context_range = { opts.context_range, 'number' },
        context_threshold = { opts.context_threshold, 'number' },
        not_same_line_penalty = { opts.not_same_line_penalty, 'number' },
        force_enable_prefix = { opts.force_enable_prefix, 'string' },
        rime_server_cmd = { opts.rime_server_cmd, 'string' },
        rime_server_address = { opts.rime_server_address, 'string' },
        shared_data_dir = { opts.shared_data_dir, 'string' },
        user_data_dir = { opts.user_data_dir, 'string' },
        max_candidates = { opts.max_candidates, 'number' },
    })

    if M.disabled == nil then
        if opts.enable == 'off' then
            M.disabled = true
            callback({
                items = {},
                isIncomplete = true,
            })
            return
        else
            M.disabled = false
        end
    end

    local text = string.sub(request.context.cursor_before_line, request.offset)
    local cursor = request.context.cursor
    local max_candidates = opts.max_candidates

    local keys = text
    if opts.enable == 'auto' then
        local detected, same_line
        keys, detected, same_line = utils.detect_context(text, cursor, opts.context_range, opts.context_threshold, opts.force_enable_prefix)
        if not detected then
            callback({
                items = {},
                isIncomplete = true,
            })
            return
        end
        if not same_line then
            max_candidates = math.ceil(max_candidates * opts.not_same_line_penalty)
        end
    end

    local select = nil
    if opts.preselect_first then
        select = 1
    end
    if opts.preselect_number then
        local index = keys:find('[0-9]+$')
        if index then
            select = tonumber(keys:sub(index, #keys))
            keys = keys:sub(1, index - 1)
        end
    end

    if not M.server then
        local thisdir = debug.getinfo(1).source:sub(2):match("(.*)/") .. "/../.."
        local cmd = "cd '" .. thisdir .. "' && " .. opts.rime_server_cmd .. " " .. opts.rime_server_address .. " >/dev/null 2>&1"
        local server = io.popen(cmd, 'r')
        if not server then
            M.server = 'EXIST'
            utils.error("--- SERVER START ERROR ---\n%s", cmd)
        else
            M.server = server
        end
    end
    local serve_address = opts.rime_server_address

    local host = 'http://' .. serve_address
    utils.rpc(host, '/rpc/get_candidates', {
        key_sequence = keys,
        max_candidates = max_candidates,
        shared_data_dir = opts.shared_data_dir,
        user_data_dir = opts.user_data_dir,
    }, function (result)
            -- print(result.candidates)
            assert(type(result.candidates) == 'table', vim.inspect(result))
            local items = {}
            for i, candidate in ipairs(result.candidates) do
                local label
                if opts.label_with_index == 'circle' then
                    label = string.format("%s %s%s", indexTab[i] or tostring(i), candidate.text, candidate.comment)
                elseif opts.label_with_index == 'number' then
                    label = string.format("%d. %s%s", i, candidate.text, candidate.comment)
                else
                    label = string.format("%s%s", candidate.text, candidate.comment)
                end
                items[#items + 1] = {
                    label = label,
                    filterText = text,
                    sortText = "~" .. tostring(i + 100000),
                    kind = 1,
                    textEdit = {
                        newText = candidate.text,
                        range = {
                            start = {
                                line = cursor.row - 1,
                                character = cursor.col - #text - 1,
                            },
                            ['end'] = {
                                line = cursor.row - 1,
                                character = cursor.col - 1,
                            },
                        },
                    }
                }
            end
            if select > 10 and select > #items then
                select = select % 10
            end
            if select and select > 0 and select <= #items then
                items[select].preselect = true
            end
            callback({
                items = items,
                isIncomplete = true,
            })
        end)
end

-- function M.complete(self, request, callback)
-- end

function M.get_position_encoding_kind()
    return 'utf-8'
end

return M
