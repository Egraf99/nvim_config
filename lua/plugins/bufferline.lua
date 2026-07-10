-- bufferline.nvim — открытые буферы как вкладки сверху экрана.
-- Расцветка не зашита в код: читается из highlight-групп текущей темы
-- (Normal, TabLine*, Diagnostic*, Comment...) и пересобирается на ColorScheme,
-- поэтому при смене темы (alabaster/gruvbox/oceanic) бар подхватывает её сам.
return {
    'akinsho/bufferline.nvim',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    event = 'VeryLazy',
    config = function()
        -- Прочитать группу как {fg=..., bg=...} в hex. Линки разворачиваем
        -- (link=false), отсутствующие поля оставляем nil — bufferline тогда
        -- берёт свой дефолт вместо жёсткого значения.
        local function hl(name)
            local ok, h = pcall(vim.api.nvim_get_hl, 0, { name = name, link = false })
            if not ok or not h then return {} end
            local out = {}
            if h.fg then out.fg = string.format('#%06x', h.fg) end
            if h.bg then out.bg = string.format('#%06x', h.bg) end
            return out
        end

        -- Собрать таблицу highlights из групп активной темы.
        local function build_highlights()
            local normal  = hl('Normal')
            local tabsel  = hl('TabLineSel')
            local tab     = hl('TabLine')
            local fillg   = hl('TabLineFill')
            local comment = hl('Comment')
            -- Акцент для индикатора — из «цветной» синтаксической группы.
            -- Перебор с фоллбэком: у некоторых тем часть групп бесцветна.
            local accentg = hl('Keyword')
            local errg    = hl('DiagnosticError')
            local warng   = hl('DiagnosticWarn')

            -- Нейтральный фон бара берём из спокойной группы, а не из громкого
            -- TabLine (в alabaster он ярко-голубой — отсюда была «синева»).
            local neutral  = hl('CursorLine').bg or hl('StatusLineNC').bg or normal.bg
            local editor   = normal.bg                    -- фон активной вкладки = фон редактора
            local text     = tabsel.fg or normal.fg       -- основной цвет текста таба
            local accent   = accentg.fg or hl('Function').fg or hl('Special').fg or text
            local err      = errg.fg
            local warn     = warng.fg or accent

            local hi = {
                fill               = { bg = neutral },
                background         = { fg = text, bg = neutral },
                buffer_visible     = { fg = text, bg = neutral },
                buffer_selected    = { fg = text, bg = editor, bold = true, italic = false },
                indicator_selected = { fg = accent, bg = editor },
                -- Разделители спрятаны: цвет сливается с фоном вкладки.
                separator          = { fg = neutral, bg = neutral },
                separator_visible  = { fg = neutral, bg = neutral },
                separator_selected = { fg = editor, bg = editor },
                -- Номера явно: на активном — акцент, на прочих — как текст (не серый).
                numbers            = { fg = text, bg = neutral },
                numbers_visible    = { fg = text, bg = neutral },
                numbers_selected   = { fg = accent, bg = editor, bold = true },
                modified           = { fg = warn, bg = neutral },
                modified_visible   = { fg = warn, bg = neutral },
                modified_selected  = { fg = warn, bg = editor },
                close_button          = { fg = text, bg = neutral },
                close_button_visible  = { fg = text, bg = neutral },
                close_button_selected = { fg = text, bg = editor },
                duplicate          = { fg = text, bg = neutral, italic = true },
                duplicate_selected = { fg = text, bg = editor, italic = true },
            }

            -- Диагностика: имя таба всегда чёрное как у обычного, отличается
            -- ТОЛЬКО фон (серый у неактивных, белый у активной). Иначе табы с
            -- ошибками получали дефолтный тёмный фон и цветной текст.
            -- Цветным оставляем лишь счётчик (error_diagnostic/warning_diagnostic).
            local states = {
                { s = '',          bg = neutral, bold = false },
                { s = '_visible',  bg = neutral, bold = false },
                { s = '_selected', bg = editor,  bold = true  },
            }
            for _, st in ipairs(states) do
                hi['diagnostic' .. st.s] = { fg = text, bg = st.bg, bold = st.bold }
                hi['hint' .. st.s]       = { fg = text, bg = st.bg, bold = st.bold }
                hi['info' .. st.s]       = { fg = text, bg = st.bg, bold = st.bold }
                hi['error' .. st.s]      = { fg = text, bg = st.bg, bold = st.bold }
                hi['warning' .. st.s]    = { fg = text, bg = st.bg, bold = st.bold }
                hi['hint_diagnostic' .. st.s]    = { fg = text, bg = st.bg }
                hi['info_diagnostic' .. st.s]    = { fg = text, bg = st.bg }
                hi['error_diagnostic' .. st.s]   = { fg = err,  bg = st.bg }
                hi['warning_diagnostic' .. st.s] = { fg = warn, bg = st.bg }
            end

            return hi
        end

        local options = {
            mode = 'buffers',                 -- показываем буферы, а не tabpages
            numbers = 'ordinal',              -- порядковый номер на вкладке (для <leader>1..9)
            diagnostics = 'nvim_lsp',         -- значки ошибок/предупреждений LSP на вкладке
            diagnostics_indicator = function(_, _, diag)
                local s = ''
                if diag.error then s = s .. ' ' .. diag.error end
                if diag.warning then s = s .. ' ' .. diag.warning end
                return s
            end,
            show_buffer_icons = false,           -- без иконок типов файлов
            show_buffer_close_icons = false,     -- без иконки закрытия на каждом табе
            show_close_icon = false,
            separator_style = 'thin',            -- разделитель скрыт (сливается с фоном, см. highlights)
            indicator = { style = 'none' },      -- без подчёркивания активного таба
            always_show_bufferline = false,      -- прятать бар, когда открыт один буфер
            offsets = {
                { filetype = 'neo-tree', text = 'Explorer', highlight = 'Directory', separator = true },
            },
        }

        local function setup()
            require('bufferline').setup { options = options, highlights = build_highlights() }
        end

        setup()
        -- Пересобрать цвета под новую тему при её смене.
        vim.api.nvim_create_autocmd('ColorScheme', { callback = setup })

        -- Клавиши (лидер = пробел). Префикс t: H/L заняты (начало/конец строки),
        -- <leader>t и ]t/[t свободны (терминал висит на аккордах <C-T>...).
        local map = vim.keymap.set
        map('n', ']b', '<cmd>BufferLineCycleNext<CR>',   { desc = 'Буфер: следующий' })
        map('n', '[b', '<cmd>BufferLineCyclePrev<CR>',   { desc = 'Буфер: предыдущий' })
        map('n', ']B', '<cmd>BufferLineMoveNext<CR>',    { desc = 'Буфер: сдвинуть вправо' })
        map('n', '[B', '<cmd>BufferLineMovePrev<CR>',    { desc = 'Буфер: сдвинуть влево' })
        map('n', '<leader>bp', '<cmd>BufferLinePick<CR>',      { desc = 'Буфер: выбрать по букве' })
        map('n', '<leader>bc', '<cmd>BufferLinePickClose<CR>', { desc = 'Буфер: закрыть по букве' })
        map('n', '<leader>bd', '<cmd>bdelete<CR>',             { desc = 'Буфер: закрыть текущий' })
        -- <leader>bo (закрыть прочие буферы) уже задан в default.lua — не трогаем.

        -- Прыжок к буферу по порядковому номеру: <leader>1 .. <leader>9
        for i = 1, 9 do
            map('n', '<leader>b' .. i, function()
                require('bufferline').go_to(i, true)
            end, { desc = 'Буфер: перейти к #' .. i })
        end
    end,
}
