local M = {}

local defaults = {
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
        ['('] = {'（', '【', '《'},
        [')'] = {'）', '】', '》'},
        ['['] = {'【', '「', '〔'},
        [']'] = {'】', '」', '〕'},
        ['<'] = {'《', '«', '⟨'},
        ['>'] = {'》', '»', '⟩'},
        [';'] = {'；'},
        [':'] = {'：'},
        [';;'] = {'：'},
        [','] = {'，'},
        ['.'] = {'。'},
        [',,'] = {'。'},
        ['?'] = {'？'},
        ['!'] = {'！'},
        ['^'] = {'……', '＾'},
        ['-'] = {'－', '—'},
        ['_'] = {'——', '＿'},
        ['+'] = {'＋', '±'},
        ['|'] = {'·', '｜'},
        ['&'] = {'§', '＆'},
        ['='] = {'＝', '〃', '々'},
        ['*'] = {'×', '・', '＊'},
        ['\\'] = {'、', '＼'},
        ['/'] = {'÷', '／'},
        ['\\\\'] = {'÷', '／'},
        ['%'] = {'％', '‰'},
        ['@'] = {'＠', '©', '®'},
        ['~'] = {'～', '≈'},
        ["'"] = {'’', '‘', '＇'},
        ['"'] = {'”', '“', '＂'},
        [' '] = {'　'},
        ['`'] = {'```'},
    },
}

function M.new()
  return setmetatable({}, { __index = M })
end

function M.get_keyword_pattern()
  -- return [[[!@#$%%%^&*()%-=_+%[%]{}%\|;:'",<%.>/?~` ]*]]
  return [[[%.,%\!?%:;%()%^%*%%+%/%-_'"%~|&@<>`]*]]
  -- return [[.*]]
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
        puncations = { opts.puncations, 'table' },
    })

    local keys = string.sub(request.context.cursor_before_line, request.offset)
    local cursor = request.context.cursor
    local items = {}
    for prefix, candidates in pairs(opts.puncations) do
        if keys == prefix then
            for i, candidate in ipairs(candidates) do
                items[#items + 1] = {
                    label = candidate,
                    filterText = keys,
                    sortText = "~" .. tostring(i + 10000),
                    kind = 0,
                    textEdit = {
                        newText = candidate,
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
        end
    end
    callback({
        items = items,
        isIncomplete = true,
    })
end

-- function M.complete(self, request, callback)
-- end

return M
