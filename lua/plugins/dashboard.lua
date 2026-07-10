-- Загрузочный экран (alpha-nvim, тема dashboard).
-- Показывает логотип, кнопки-действия и список недавних файлов из :oldfiles,
-- чтобы одной клавишей вернуться к недавно закрытому файлу.
return {
  "goolord/alpha-nvim",
  event = "VimEnter",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  config = function()
    local alpha = require("alpha")
    local dashboard = require("alpha.themes.dashboard")

    -- ── Заголовок ─────────────────────────────────────────────
    dashboard.section.header.val = {
      "███╗   ██╗██╗   ██╗██╗███╗   ███╗",
      "████╗  ██║██║   ██║██║████╗ ████║",
      "██╔██╗ ██║██║   ██║██║██╔████╔██║",
      "██║╚██╗██║╚██╗ ██╔╝██║██║╚██╔╝██║",
      "██║ ╚████║ ╚████╔╝ ██║██║ ╚═╝ ██║",
      "╚═╝  ╚═══╝  ╚═══╝  ╚═╝╚═╝     ╚═╝",
    }
    -- Табличная форма hl: alpha прибавляет к границам левый отступ (margin),
    -- поэтому подсветка идёт от начала элемента до его конца, а не от левого
    -- края экрана. Для многострочного заголовка задаём диапазон на каждую
    -- строку с концом = её байтовой длине.
    local header_hl = {}
    for i, line in ipairs(dashboard.section.header.val) do
      header_hl[i] = { { "AlphaHeader", 0, #line } }
    end
    dashboard.section.header.opts.hl = header_hl
    dashboard.section.header.opts.position = "left"
    dashboard.section.header.opts.shrink_margin = false -- сдвиг margin такой же, как у остальных

    -- Кнопка с равнением по левому краю: шорткат стоит в самой левой
    -- колонке (align_shortcut="left" → alpha рендерит shortcut .. текст),
    -- поэтому буквы и цифры выстраиваются в одну колонку.
    local function left_button(sc, txt, cmd)
      local b = dashboard.button(sc .. "  ", txt, cmd) -- 2 пробела = отступ шортката от текста
      b.opts.position = "left"
      b.opts.align_shortcut = "left"
      b.opts.hl_shortcut = "AlphaShortcut"
      b.opts.cursor = 0
      b.opts.width = 60
      b.opts.shrink_margin = false -- держать левый отступ даже у длинных строк
      return b
    end

    -- ── Кнопки-действия ───────────────────────────────────────
    dashboard.section.buttons.val = {
      left_button("e", "  Новый файл", "<cmd>ene | startinsert<cr>"),
      left_button("f", "  Найти файл", "<cmd>Telescope find_files<cr>"),
      left_button("r", "  Недавние файлы", "<cmd>Telescope oldfiles<cr>"),
      left_button("g", "  Поиск по тексту", "<cmd>Telescope live_grep<cr>"),
      left_button("c", "  Конфиг", "<cmd>edit $MYVIMRC<cr>"),
      left_button("l", "󰒲  Lazy", "<cmd>Lazy<cr>"),
      left_button("q", "  Выход", "<cmd>qa<cr>"),
    }

    -- ── Секция «Недавние файлы» ────────────────────────────────
    -- Клавиши 1..9 открывают соответствующий файл напрямую.
    local function icon(fn)
      local ok, devicons = pcall(require, "nvim-web-devicons")
      if not ok then
        return "", ""
      end
      local ext = fn:match("%.(%w+)$") or ""
      local ico, hl = devicons.get_icon(fn, ext, { default = true })
      return ico or "", hl or ""
    end

    local function recent_files(max)
      max = max or 9
      local buttons = {}
      local shown = 0
      for _, file in ipairs(vim.v.oldfiles) do
        if shown >= max then
          break
        end
        if vim.fn.filereadable(file) == 1 then
          shown = shown + 1
          local ico, ico_hl = icon(file)
          -- Путь относительно $HOME; длинный обрезаем слева, сохраняя имя файла.
          local short = vim.fn.fnamemodify(file, ":~")
          local maxlen = 48
          if vim.fn.strchars(short) > maxlen then
            short = "…" .. vim.fn.strcharpart(short, vim.fn.strchars(short) - maxlen + 1)
          end
          local key = tostring(shown)
          local btn = left_button(
            key,
            string.format("%s  %s", ico, short),
            "<cmd>edit " .. vim.fn.fnameescape(file) .. "<cr>"
          )
          -- Подсветка иконки своим цветом типа файла (alpha сам сдвинет
          -- смещение на длину шортката, т.к. align_shortcut="left").
          btn.opts.hl = { { ico_hl, 0, #ico + 2 } }
          table.insert(buttons, btn)
        end
      end
      return {
        type = "group",
        val = {
          { type = "padding", val = 1 },
          {
            type = "text",
            val = "Недавние файлы",
            opts = { hl = { { "AlphaHeading", 0, -1 } }, position = "left", shrink_margin = false },
          },
          { type = "padding", val = 1 },
          { type = "group", val = buttons },
        },
      }
    end

    -- ── Сборка layout ─────────────────────────────────────────
    local layout = {
      { type = "padding", val = 2 },
      dashboard.section.header,
      { type = "padding", val = 2 },
      dashboard.section.buttons,
      recent_files(9),
      { type = "padding", val = 1 },
      dashboard.section.footer,
    }
    dashboard.config.layout = layout
    dashboard.opts.opts.noautocmd = true

    -- ── Горизонтальный сдвиг всего контента ───────────────────
    -- Левый отступ = 30% ширины окна: alpha применяет opts.margin ко всем
    -- элементам (position ≠ center) и учитывает его в подсветке, поэтому
    -- взаимное выравнивание и вертикальные отступы остаются прежними —
    -- блок целиком уезжает вправо.
    local MARGIN_RATIO = 0.3
    local function update_margin()
      dashboard.config.opts.margin = math.floor(vim.o.columns * MARGIN_RATIO)
    end
    update_margin()
    vim.api.nvim_create_autocmd("VimResized", {
      callback = function()
        update_margin()
        pcall(vim.cmd.AlphaRedraw)
      end,
    })

    -- ── Футер: сколько плагинов и как быстро стартовали ───────
    vim.api.nvim_create_autocmd("User", {
      pattern = "LazyVimStarted",
      callback = function()
        local stats = require("lazy").stats()
        local ms = math.floor(stats.startuptime * 100 + 0.5) / 100
        dashboard.section.footer.val =
          string.format("%d плагинов загружено за %s мс", stats.count, ms)
        dashboard.section.footer.opts.hl = { { "AlphaFooter", 0, -1 } }
        dashboard.section.footer.opts.position = "left"
        dashboard.section.footer.opts.shrink_margin = false
        pcall(vim.cmd.AlphaRedraw)
      end,
    })

    -- ── Подсветка (привязана к текущей теме) ──────────────────
    local function set_hl()
      vim.api.nvim_set_hl(0, "AlphaHeader", { link = "Function", default = true })
      vim.api.nvim_set_hl(0, "AlphaHeading", { link = "Title", default = true })
      vim.api.nvim_set_hl(0, "AlphaFooter", { link = "Comment", default = true })
      vim.api.nvim_set_hl(0, "AlphaShortcut", { link = "Special", default = true })
    end
    set_hl()
    vim.api.nvim_create_autocmd("ColorScheme", { callback = set_hl })

    alpha.setup(dashboard.config)

    -- Не мешать lazy: скрыть alpha, когда открываем окно плагинов.
    vim.api.nvim_create_autocmd("User", {
      pattern = "AlphaReady",
      callback = function()
        vim.opt_local.laststatus = 0
        vim.opt_local.showtabline = 0
        vim.api.nvim_create_autocmd("BufUnload", {
          buffer = 0,
          callback = function()
            vim.opt.laststatus = 3
            vim.opt.showtabline = 2
          end,
        })
      end,
    })
  end,
}
