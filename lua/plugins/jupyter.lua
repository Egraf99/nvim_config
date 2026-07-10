function ToDev()
    vim.cmd [[ :%substitute/\zeHRDWHJob/Dev/g ]]
    vim.cmd [[ :nohlsearch ]]
end
function ToProd()
    vim.cmd [[ :%substitute/Dev\zeHRDWHJob//g ]]
    vim.cmd [[ :nohlsearch ]]
end


return {
    {
        "benlubas/molten-nvim",
        version = "^1.0.0", -- use version <2.0.0 to avoid breaking changes
        ft = { "python" },  -- грузим только для python-буферов
        build = ":UpdateRemotePlugins",
        init = function()
            -- Питон-хост для remote-плагина molten: выделенный venv с pynvim>=0.6 + jupyter_client.
            -- Прибиваем явно, чтобы не зависеть от того, какой python3 найдёт nvim в PATH (pyenv/system).
            vim.g.python3_host_prog = vim.fn.expand("~/.virtualenvs/neovim/bin/python")

            vim.keymap.set("n", "<leader>ri", ":MoltenInit http://localhost:8889/<CR>",                   { silent = false, desc = "Initialize the plugin" })
            vim.keymap.set("n", "<leader>re", ":MoltenEvaluateOperator<CR>",       { silent = false, desc = "run operator selection" })
            vim.keymap.set("n", "<leader>rl", ":MoltenEvaluateLine<CR>",           { silent = false, desc = "evaluate line" })
            vim.keymap.set("n", "<leader>rr", ":MoltenReevaluateCell<CR>",                          { silent = false, desc = "re-evaluate cell" })
            vim.keymap.set("n", "<leader>rc", ":MoltenEvaluateOperator<CR>iz",                      { silent = false, desc = "evaluate fold" })
            vim.keymap.set("v", "<leader>r",  ":<C-u>MoltenEvaluateVisual<CR>",    { silent = true, desc = "molten delete cell" })
            vim.keymap.set("n", "<leader>rd", ":MoltenDelete<CR>",                                  { silent = true, desc = "molten delete cell" })
            vim.keymap.set("n", "<leader>k",  ":MoltenHideOutput<CR>",                              { silent = true, desc = "hide output" })
            vim.keymap.set("n", "<leader>j",  ":noautocmd MoltenEnterOutput<CR>",                   { silent = true, desc = "show/enter output" })
            vim.keymap.set("n", "<leader>rs",  ":MoltenInterrupt<CR>",                              { silent = true, desc = "interrupt cell" })

            vim.g.molten_output_win_max_height = 40
            vim.g.molten_auto_open_output = false
            vim.g.molten_output_win_style = "minimal"
            vim.g.molten_output_show_more = true
            vim.g.molten_use_border_highlights = true

            -- Инлайн-картинки (matplotlib/plotly и т.п.) через image.nvim в kitty
            vim.g.molten_image_provider = "image.nvim"
            vim.g.molten_virt_text_output = true   -- текстовый вывод как virtual text под ячейкой
            vim.g.molten_wrap_output = true

            -- Highlighting
            vim.api.nvim_set_hl(0, "MoltenOutputBorderFail", { link = "DiagnosticError" })
            vim.api.nvim_set_hl(0, "MoltenOutputBorderSuccess", { link = "DiagnosticOk" })

            -- Custom comands
            vim.api.nvim_create_user_command( 'Toprod', function() ToProd() end, {} )
            vim.keymap.set("n", "<leader>p", ":Toprod<CR>", { silent = false, desc = "To production" })
            vim.api.nvim_create_user_command( 'Todev', function() ToDev() end, {} )
            vim.keymap.set("n", "<leader>d", ":Todev<CR>", { silent = false, desc = "To dev" })

        end,
    },
    {
        -- Инлайн-рендер картинок в kitty; molten шлёт свои изображения именно сюда
        "3rd/image.nvim",
        ft = { "python", "markdown" },
        -- Нужен только консольный ImageMagick. processor magick_cli сам берёт
        -- `magick` (IM7), а если его нет — откатывается на `convert`/`identify` (IM6).
        -- luarock `magick` НЕ требуется — он нужен только процессору magick_rock.
        opts = {
            backend = "kitty",
            processor = "magick_cli",  -- через консольный бинарь, без luajit-биндингов
            integrations = {
                markdown = { enabled = true },
            },
            max_width = 100,
            max_height = 12,
            max_height_window_percentage = math.huge,
            max_width_window_percentage = math.huge,
            window_overlap_clear_enabled = true,
            window_overlap_clear_ft_ignore = { "cmp_menu", "cmp_docs", "" },
        },
    },
}
