# cmp-rime

本插件是 [nvim-cmp](https://github.com/hrsh7th/nvim-cmp) 的扩展模块。

通过补全的方式在 NeoVim 中轻松输入中文。

基于 [RIME 输入法](https://rime.im/)。

# 演示

[Screencast from 07-19-2022 01:19:05 PM.webm](https://user-images.githubusercontent.com/17873203/179807390-63111509-acb0-4870-927b-b44b728c39bf.webm)


# 配置

安装 rime_server 所需依赖项:

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
                      -- 这是 cmp-rime 的配置
                      name = 'rime',
                      option = {
                          -- 设置一次最多显示的候选项数量:
                          max_candidates = 10,

                          -- 设置配置文件目录，您可以设置和系统内的输入法共享
                          -- 对于 fcitx 用户:
                          user_data_dir = vim.fn.getenv('HOME') .. '/.config/fcitx/rime',
                          -- 对于 fcitx5 用户:
                          user_data_dir = vim.fn.getenv('HOME') .. '/.config/share/fcitx5/rime',
                          -- 对于 ibus 用户:
                          user_data_dir = vim.fn.getenv('HOME') .. '/.config/ibus/rime',
                      },
                  },
            },
        }
    end
}
```
