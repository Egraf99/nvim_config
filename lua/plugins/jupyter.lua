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
        -- Наши патчи molten (outputbuffer.py) + штатный UpdateRemotePlugins.
        -- lazy перезаливает файлы плагина при обновлении, поэтому переприменяем
        -- идемпотентно: если маркер патча уже есть — не трогаем; если апстрим
        -- сдвинул код и якорь не найден — не ломаем сборку, а предупреждаем.
        build = function(plugin)
            local path = plugin.dir .. "/rplugin/python3/molten/outputbuffer.py"
            local patches = {
                {
                    -- Фиксированная высота блока virtual-text (код ниже не смещается)
                    marker = "molten%-fixed%-height%-patch",
                    old = [==[        l = len(lines)
        if l > self.options.virt_text_max_lines:
            lines = lines[: self.options.virt_text_max_lines - 1]
            lines.append(f"󰁅 {l - self.options.virt_text_max_lines + 1} More Lines ")]==],
                    new = [==[        # --- molten-fixed-height-patch (khodinegor) ---
        # Держим virtual-text постоянной высоты, чтобы код ниже не смещался.
        # lines[0] — статусный заголовок, дальше идёт сам вывод ячейки.
        try:
            _fixed = int(self.nvim.api.get_var("molten_virt_text_fixed_lines"))
        except Exception:
            _fixed = 4
        _header, _content = lines[0], lines[1:]
        _l = len(_content)
        if _l > _fixed:
            # вывод выше блока — режем и последней строкой пишем, сколько под катом
            _content = _content[: _fixed - 1]
            _content.append(f"󰁅 {_l - _fixed + 1} More Lines ")
        while len(_content) < _fixed:
            # добиваем пустыми, чтобы высота блока была постоянной
            _content.append("")
        lines = [_header] + _content
        # --- end molten-fixed-height-patch ---]==],
                },
                {
                    -- Индикация статуса в первой строке virt-text (цвет ✓/✗)
                    marker = "molten%-virt%-status%-hl%-patch",
                    old = [==[        self.virt_text_id = buf.api.set_extmark(
            self.extmark_namespace,
            win_row,
            0,
            {
                "virt_lines": [[(line, self.options.hl.virtual_text)] for line in lines],
            },
        )]==],
                    new = [==[        # --- molten-virt-status-hl-patch (khodinegor) ---
        # Первую строку (статус ✓/✗) красим по результату, остальные — серым.
        _vt = self.options.hl.virtual_text
        if not self.output.success:
            _first_hl = "MoltenVirtualTextFail"
        elif self.output.status == OutputStatus.DONE:
            _first_hl = "MoltenVirtualTextOk"
        else:
            _first_hl = _vt
        self.virt_text_id = buf.api.set_extmark(
            self.extmark_namespace,
            win_row,
            0,
            {
                "virt_lines": [
                    [(line, _first_hl if i == 0 else _vt)] for i, line in enumerate(lines)
                ],
            },
        )
        # --- end molten-virt-status-hl-patch ---]==],
                },
                {
                    -- Окно вывода (MoltenEnterOutput) — центрированный float 80%×80%
                    marker = "molten%-float%-80%-patch",
                    old = [==[                "focusable": False,
            }
            if self.options.output_win_style:]==],
                    new = [==[                "focusable": False,
            }
            # --- molten-float-80-patch (khodinegor) ---
            # Крупный центрированный float вместо окна под ячейкой: 80%×80%
            # экрана. show_floating_win зовётся и при обновлениях окна, поэтому
            # размер держится стабильно и не «схлопывается» обратно под ячейку.
            _cols = self.nvim.api.get_option_value("columns", {})
            _rows = self.nvim.api.get_option_value("lines", {})
            _fw = int(_cols * 0.8)
            _fh = int(_rows * 0.8)
            win_opts["relative"] = "editor"
            win_opts["width"] = _fw
            win_opts["height"] = _fh
            win_opts["row"] = (_rows - _fh) // 2
            win_opts["col"] = (_cols - _fw) // 2
            # --- end molten-float-80-patch ---
            if self.options.output_win_style:]==],
                },
            }
            local fh = io.open(path, "r")
            if not fh then
                vim.cmd("UpdateRemotePlugins")
                return
            end
            local src = fh:read("*a")
            fh:close()
            local changed = false
            for _, p in ipairs(patches) do
                if not src:find(p.marker) then
                    local i = src:find(p.old, 1, true)
                    if i then
                        src = src:sub(1, i - 1) .. p.new .. src:sub(i + #p.old)
                        changed = true
                    else
                        vim.notify(
                            "molten patch '" .. p.marker .. "': якорь не найден, пропускаю (проверь outputbuffer.py)",
                            vim.log.levels.WARN
                        )
                    end
                end
            end
            if changed then
                local w = io.open(path, "w")
                w:write(src)
                w:close()
            end
            vim.cmd("UpdateRemotePlugins")
        end,
        init = function()
            -- Питон-хост для remote-плагина molten: выделенный venv с pynvim>=0.6 + jupyter_client.
            -- Прибиваем явно, чтобы не зависеть от того, какой python3 найдёт nvim в PATH (pyenv/system).
            vim.g.python3_host_prog = vim.fn.expand("~/.virtualenvs/neovim/bin/python")

            vim.keymap.set("n", "<leader>ri", ":MoltenInit http://localhost:8889/<CR>", { silent = false, desc = "Initialize the plugin" })
            vim.keymap.set("n", "<leader>re", ":MoltenEvaluateOperator<CR>",            { silent = false, desc = "run operator selection" })
            vim.keymap.set("n", "<leader>rl", ":MoltenEvaluateLine<CR>",                { silent = false, desc = "evaluate line" })
            vim.keymap.set("n", "<leader>rr", ":MoltenReevaluateCell<CR>",              { silent = false, desc = "re-evaluate cell" })
            vim.keymap.set("n", "<leader>rc", ":MoltenEvaluateOperator<CR>iz",          { silent = false, desc = "evaluate fold" })
            vim.keymap.set("v", "<leader>r",  ":<C-u>MoltenEvaluateVisual<CR>",         { silent = true, desc = "molten delete cell" })
            vim.keymap.set("n", "<leader>rd", ":MoltenDelete<CR>",                      { silent = true, desc = "molten delete cell" })
            vim.keymap.set("n", "<leader>k",  ":MoltenHideOutput<CR>",                  { silent = true, desc = "hide output" })
            vim.keymap.set("n", "<leader>j",  ":noautocmd MoltenEnterOutput<CR>",       { silent = true, desc = "show/enter output (float 80%×80%)" })
            vim.keymap.set("n", "<leader>rs", ":MoltenInterrupt<CR>",                   { silent = true, desc = "interrupt cell" })

            vim.g.molten_output_win_max_height = 40
            vim.g.molten_auto_open_output = false
            vim.g.molten_output_win_style = "minimal"
            vim.g.molten_output_show_more = true
            vim.g.molten_use_border_highlights = true
            -- Рамка окна вывода — полный одинарный бокс, как у toggleterm (дефолт
            -- molten — только верхняя линия). Таблица из 8 символов обязательна,
            -- т.к. use_border_highlights красит рамку только для border-таблицы.
            -- Порядок nvim: [tl, top, tr, right, br, bottom, bl, left].
            vim.g.molten_output_win_border = { "┌", "─", "┐", "│", "┘", "─", "└", "│" }
            -- Не срезать нижнюю линию рамки. molten с output_crop_border=true (дефолт)
            -- обнуляет border[5], когда вывод не влезает под курсором — решение по
            -- win_row исходного окна, ДО того как наш molten-float-80-patch переставит
            -- окно в центр. Из-за этого нижней границы не было никогда. Наш float
            -- фиксированного размера, экономить строку не нужно.
            vim.g.molten_output_crop_border = false

            -- Инлайн-картинки (matplotlib/plotly и т.п.) через image.nvim в kitty
            vim.g.molten_image_provider = "image.nvim"
            vim.g.molten_virt_text_output = true   -- текстовый вывод как virtual text под ячейкой
            vim.g.molten_wrap_output = false
            -- Фиксированная высота блока virtual-text (строк вывода, без заголовка).
            -- Короткий вывод паддится пустыми, длинный режется со счётчиком «More Lines».
            -- Читается нашим патчем molten (см. build ниже) — код ниже не смещается.
            vim.g.molten_virt_text_fixed_lines = 4

            -- Highlighting. Цвета molten задаём функцией и переприменяем на
            -- ColorScheme: colorscheme делает `hi clear` и затирает группы,
            -- выставленные в init один раз, — из-за этого текст вывода уходил
            -- в дефолт (тёмный). Тот же приём уже есть в dashboard/bufferline.
            local function set_molten_hl()
                -- Вид float-окна вывода под toggleterm: фон и рамка на Normal
                -- (у toggleterm NormalFloat и FloatBorder слинкованы на Normal),
                -- без статусной раскраски рамки. winhighlight molten мапит
                -- Normal→MoltenOutputWin, NormalNC→MoltenOutputWinNC, а рамку
                -- (use_border_highlights) — на Border-группы; линкуем всё на Normal.
                vim.api.nvim_set_hl(0, "MoltenOutputWin", { link = "Normal" })
                vim.api.nvim_set_hl(0, "MoltenOutputWinNC", { link = "Normal" })
                vim.api.nvim_set_hl(0, "MoltenOutputBorder", { link = "Normal" })
                vim.api.nvim_set_hl(0, "MoltenOutputBorderFail", { link = "Normal" })
                vim.api.nvim_set_hl(0, "MoltenOutputBorderSuccess", { link = "Normal" })
                vim.api.nvim_set_hl(0, "MoltenOutputFooter", { link = "Normal" })
                -- Текст virtual-text вывода: по умолчанию линкуется на Comment (жёлтый).
                -- Делаем серым — это s:fg_grey_very_light (#bbbbbb) из alabaster-bg.vim.
                vim.api.nvim_set_hl(0, "MoltenVirtualText", { fg = "#bbbbbb" })
                -- Индикация статуса в первой строке virt-text (наш патч): красим
                -- только заголовок ✓/✗, остальные строки остаются серыми.
                -- Явные цвета, а не линк на Diagnostic*: в этой светлой теме
                -- DiagnosticOk — тёмно-зелёный #003113 (читается как чёрный),
                -- а DiagnosticError — оранжевый. Берём чистые зелёный/красный.
                vim.api.nvim_set_hl(0, "MoltenVirtualTextOk", { fg = "#2e9e44" })
                vim.api.nvim_set_hl(0, "MoltenVirtualTextFail", { fg = "#d11a1a" })
            end
            set_molten_hl()
            vim.api.nvim_create_autocmd("ColorScheme", { callback = set_molten_hl })

            -- Custom comands
            vim.api.nvim_create_user_command( 'Toprod', function() ToProd() end, {} )
            vim.keymap.set("n", "<leader>p",  ":Toprod<CR>",                            { silent = false, desc = "To production" })
            vim.api.nvim_create_user_command( 'Todev', function() ToDev() end, {} )
            vim.keymap.set("n", "<leader>d",  ":Todev<CR>",                             { silent = false, desc = "To dev" })

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
