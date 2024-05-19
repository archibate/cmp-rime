# cmp-rime

本插件是 [nvim-cmp](https://github.com/hrsh7th/nvim-cmp) 的扩展模块。

通过补全的方式在 NeoVim 中轻松输入中文。

基于 [RIME 输入法](https://rime.im/)。

# 演示

[Screencast from 07-19-2022 01:19:05 PM.webm](https://user-images.githubusercontent.com/17873203/179807390-63111509-acb0-4870-927b-b44b728c39bf.webm)

# 配置

安装所需依赖项:
```bash
pacman -S librime liburing bearssl
```

推荐使用 [packer.nvim](https://github.com/wbthomason/packer.nvim) 来管理 NeoVim 插件：
```lua
use {
    'hrsh7th/nvim-cmp',
    requires = {
        'archibate/cmp-rime',
        run = 'make',  -- 构建 rime_server，当你首次输入中文时，会自动启动该程序
    },
    config = function()
        require('cmp').setup {
            ...  -- 这里可以有你其他的 cmp 配置
            sources = {
                  ...  -- 这里可以有你其他的补全模块，比如 nvim-lsp
                  {
                      -- 这是我们中文输入法的配置
                      name = 'rime',
                      option = {
                          max_candidates = 8, -- 一次最多显示的候选项数量

                          enable = 'auto',
                          -- 'on' - 始终启用中文输入补全
                          -- 'off' - 始终禁止中文输入补全
                          -- 'auto' - 根据上下文自动决定要不要启用中文输入

                          context_range = 15, -- ±15 行上下文范围
                          context_threshold = 0.2, -- 由上下文中的中文字符触发时，需要至少 20% 为中文字符
                          not_same_line_penalty = 0.7, -- 由上下文中的中文字符触发时，候选词数量减少至 70%
                          force_enable_prefix = 'rime', -- 检测到此前缀或后缀后无视上下文强制启用

                          user_data_dir = vim.fn.getenv('HOME') .. '/.local/share/cmp-rime',
                          -- 您也可以设置为和系统内的输入法共享配置，例如对于 fcitx 用户:
                          user_data_dir = vim.fn.getenv('HOME') .. '/.config/fcitx/rime',
                          -- 对于 fcitx5 用户:
                          user_data_dir = vim.fn.getenv('HOME') .. '/.config/share/fcitx5/rime',
                          -- 对于 ibus 用户:
                          user_data_dir = vim.fn.getenv('HOME') .. '/.config/ibus/rime',
                      },
                  },
                  {
                      --（可选）支持全角标点和特殊符号输入
                      name = 'rime_punct',
                      option = {
                          enable = 'auto',
                          context_range = 5,
                          context_threshold = 0.2,
                          force_enable_prefix = 'rime',
                      },
                  },
            },
        }
    end
}
```
