local M = {}

local utils = require 'cmp-rime.utils'

local defaults = {
    enable = 'auto',
    preselect_first = true,
    context_range = 2,
    context_threshold = 1,
    force_enable_prefix = 'rime',

    -- puncations = {
    --     ['!'] = '！',
    --     ['@'] = '＠',
    --     ['#'] = '＃',
    --     ['$'] = '＄',
    --     ['%'] = '％',
    --     ['^'] = '＾',
    --     ['&'] = '＆',
    --     ['*'] = '＊',
    --     ['('] = '（',
    --     [')'] = '）',
    --     ['-'] = '－',
    --     ['_'] = '＿',
    --     ['+'] = '＋',
    --     ['='] = '＝',
    --     ['['] = '【',
    --     [']'] = '】',
    --     ['{'] = '｛',
    --     ['}'] = '｝',
    --     ['\\'] = '、',
    --     ['|'] = '｜',
    --     [';'] = '；',
    --     [':'] = '：',
    --     ["'"] = '＇',
    --     ['"'] = '＂',
    --     [','] = '，',
    --     ['.'] = '。',
    --     ['<'] = '《',
    --     ['>'] = '》',
    --     ['/'] = '／',
    --     ['?'] = '？',
    --     ['~'] = '～',
    --     ['`'] = '｀',
    --     [' '] = '　',
    -- },
    puncations = {
        ['('] = {'（'},
        [')'] = {'）'},
        ['['] = {'【'},
        [']'] = {'】'},
        ['[['] = {'「'},
        [']]'] = {'」'},
        ['[[['] = {'『'},
        [']]]'] = {'』'},
        ['<'] = {'＜'},
        ['>'] = {'＞'},
        ['<='] = {'≤'},
        ['>='] = {'≥'},
        ['<<'] = {'《'},
        ['>>'] = {'》'},
        ['<<<'] = {'«'},
        ['>>>'] = {'»'},
        [';'] = {'；'},
        [':'] = {'：'},
        [';;'] = {'：'}, -- sometimes failed to type `:`
        [','] = {'，'},
        ['.'] = {'。'},
        [',,'] = {'。'}, -- sometimes failed to type `.`
        ['?'] = {'？'},
        ['!'] = {'！'},
        ['^'] = {'……'},
        ['..'] = {'…'},
        ['-'] = {'—'},
        ['__'] = {'——'},
        ['+'] = {'＋'},
        ['+-'] = {'±'},
        ['|'] = {'｜'},
        ['||'] = {'‖'},
        ['|_'] = {'⊥'},
        ['&'] = {'＆'},
        ['&&'] = {'∵'},
        ['='] = {'＝'},
        ['=='] = {'≡'},
        ['$'] = {'§'},
        ['$/'] = {'∂'},
        ['$*'] = {'∫'},
        ['$**'] = {'∬'},
        ['$***'] = {'∭'},
        ['$*-'] = {'∮'},
        ['$**-'] = {'∯'},
        ['$***-'] = {'∰'},
        ['$+'] = {'∑'},
        ['$<'] = {'∈'},
        ['$-'] = {'√'},
        ['*'] = {'×'},
        ['.*'] = {'·'},
        ['**'] = {'・'},
        ['\\'] = {'、'},
        ['/'] = {'÷'},
        ['\\\\'] = {'÷'}, -- sometimes failed to type `/`
        ['%'] = {'％'},
        ['%%'] = {'‰'},
        ['%%%'] = {'‱'},
        ['%-'] = {'℃'},
        ['%+'] = {'℉'},
        ['#'] = {'＃'},
        ['@'] = {'＠'},
        ['@@'] = {'©'},
        ['~'] = {'～'},
        ['~='] = {'≈'},
        ['!='] = {'≠'},
        ["'"] = {'’'},
        ['"'] = {'”'},
        ["''"] = {'‘'},
        ['""'] = {'“'},
        ['~~'] = {'　'},
        ['`'] = {'```'},
        ['->'] = {'→'},
        ['<-'] = {'←'},
        ['|^'] = {'↑'},
        ['|>'] = {'↓'},
        ['>-'] = {'➤'},
        ['<->'] = {'↔'},
        ['()'] = {'○'},
        ['(.)'] = {'⊙'},
        ['(())'] = {'◎'},
        ['(+)'] = {'⊕'},
        ['(*)'] = {'●'},
        ['(<)'] = {'↺'},
        ['(>)'] = {'↻'},
        ['<>'] = {'◇'},
        ['<*>'] = {'◆'},
        ['=>'] = {'⇒'},
        ['=<'] = {'⇐'},
        ['<=>'] = {'⇔'},
        ['||^'] = {'⇑'},
        ['||>'] = {'⇓'},
        ['[+'] = {'✔'},
        ['[-'] = {'✘'},
        -- ['1'] = {'①'},
        -- ['2'] = {'②'},
        -- ['3'] = {'③'},
        -- ['4'] = {'④'},
        -- ['5'] = {'⑤'},
        -- ['6'] = {'⑥'},
        -- ['7'] = {'⑦'},
        -- ['8'] = {'⑧'},
        -- ['9'] = {'⑨'},
        -- ['10'] = {'⑩'},
        -- ['11'] = {'⑪'},
        -- ['12'] = {'⑫'},
        -- ['13'] = {'⑬'},
        -- ['14'] = {'⑭'},
        -- ['15'] = {'⑮'},
        -- ['16'] = {'⑯'},
        -- ['17'] = {'⑰'},
        -- ['18'] = {'⑱'},
        -- ['19'] = {'⑲'},
        -- ['20'] = {'⑳'},
        -- ['0'] = {'○'},
        -- ['00'] = {'∅'},
        -- ['000'] = {'●'},
    },
}

function M.new()
    return setmetatable({}, { __index = M })
end

function M.get_keyword_pattern()
    if M.disabled then
        return [[]]
    end
    return [[[%.,%\!?%:;%()%^%*%%+%/%-_'"%~|&@<>`$#]*]]
end

function M.complete(_, request, callback)
    local opts = vim.tbl_deep_extend('keep', request.option, defaults)
    vim.validate({
        enable = { opts.enable, 'string' },
        preselect_first = { opts.preselect_first, 'boolean' },
        context_range = { opts.context_range, 'number' },
        context_threshold = { opts.context_threshold, 'number' },
        force_enable_prefix = { opts.force_enable_prefix, 'string' },
        puncations = { opts.puncations, 'table' },
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

    local keys = text
    if opts.enable == 'auto' then
        local detected
        keys, detected = utils.detect_context(keys, cursor, opts.context_range, opts.context_threshold, opts.force_enable_prefix)
        if not detected then
            callback({
                items = {},
                isIncomplete = true,
            })
            return
        end
    end

    local items = {}
    for prefix, candidates in pairs(opts.puncations) do
        if keys == prefix then
            for i, candidate in ipairs(candidates) do
                items[#items + 1] = {
                    label = candidate,
                    filterText = keys,
                    sortText = "~" .. tostring(i + 10000),
                    kind = 1,
                    textEdit = {
                        newText = candidate,
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
        end
    end
    if opts.preselect_first and #items > 0 then
        items[1].preselect = true
    end
    callback({
        items = items,
        isIncomplete = true,
    })
end

-- function M.complete(self, request, callback)
-- end

function M.get_position_encoding_kind()
    return 'utf-8'
end

return M
