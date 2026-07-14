-- arc-signs.nvim — gutter-знаки изменений относительно arc HEAD + навигация
-- по ханкам и превью. Дёргает `arc diff --git -U0 <file>`, парсит git-unified
-- (@@-хедеры и тело) и расставляет extmark-знаки в signcolumn.
-- Аналог gitsigns, но под Arc VCS. Только stdlib nvim, без зависимостей.

local M = {}

local ns = vim.api.nvim_create_namespace("arc_signs")
local ns_preview = vim.api.nvim_create_namespace("arc_signs_preview")

local config = {
  debounce = 250, -- мс между событием и запуском arc
  events = { "BufReadPost", "BufWritePost", "BufEnter" },
  auto_signcolumn = true, -- принудительно включать signcolumn в arc-буферах
  keymaps = true,         -- ]c / [c / <leader>hp в arc-буферах
  signs = {
    add          = { text = "▏", hl = "ArcSignsAdd" },
    change       = { text = "▏", hl = "ArcSignsChange" },
    delete       = { text = "_", hl = "ArcSignsDelete" },
    topdelete    = { text = "‾", hl = "ArcSignsDelete" },
    changedelete = { text = "⌊", hl = "ArcSignsChange" },
  },
}

local timers = {}     -- bufnr -> uv_timer (дебаунс)
local root_cache = {} -- dir -> arcadia root | false
local state = {}      -- bufnr -> список ханков последнего refresh

-- Подсветка знаков. Переиспользуем цвета gitsigns/diff, если они есть,
-- иначе задаём разумный fg. default=true — пользователь легко переопределит.
local function define_highlights()
  local map = {
    ArcSignsAdd    = { links = { "GitSignsAdd", "diffAdded", "Added" },       fg = "#4fa65a" },
    ArcSignsChange = { links = { "GitSignsChange", "diffChanged", "Changed" }, fg = "#c7a03b" },
    ArcSignsDelete = { links = { "GitSignsDelete", "diffRemoved", "Removed" }, fg = "#c0392b" },
  }
  for name, spec in pairs(map) do
    local linked
    for _, cand in ipairs(spec.links) do
      if vim.fn.hlexists(cand) == 1 then linked = cand break end
    end
    if linked then
      vim.api.nvim_set_hl(0, name, { link = linked, default = true })
    else
      vim.api.nvim_set_hl(0, name, { fg = spec.fg, default = true })
    end
  end
end

-- Корень Аркадии для файла (маркер .arcadia.root вверх по дереву).
-- Кэшируем по каталогу, чтобы не спавнить arc на посторонних файлах.
local function arcadia_root(file)
  local dir = vim.fs.dirname(file)
  local cached = root_cache[dir]
  if cached ~= nil then return cached or nil end
  local root = vim.fs.root(file, { ".arcadia.root" })
  root_cache[dir] = root or false
  return root
end

local function buf_valid(bufnr)
  return vim.api.nvim_buf_is_valid(bufnr)
    and vim.bo[bufnr].buftype == "" -- только обычные файловые буферы
end

local function file_of(bufnr)
  local name = vim.api.nvim_buf_get_name(bufnr)
  if name == "" or vim.fn.filereadable(name) == 0 then return nil end
  return name
end

-- Парсинг @@ -a,b +c,d @@ и тела ханка. Счётчик по умолчанию = 1 (git опускает ",1").
-- Для каждого ханка собираем old_lines ('-') и new_lines ('+') для превью.
local function parse(out)
  local hunks = {}
  local cur
  for line in vim.gsplit(out, "\n", { plain = true }) do
    local oc, ns_, nc = line:match("^@@ %-%d+,?(%d*) %+(%d+),?(%d*) @@")
    if ns_ then
      local old_count = (oc == "") and 1 or tonumber(oc)
      local new_start = tonumber(ns_)
      local new_count = (nc == "") and 1 or tonumber(nc)
      local kind
      if old_count == 0 then
        kind = "add"          -- @@ -a,0 +c,d @@ — только добавление
      elseif new_count == 0 then
        kind = "delete"       -- @@ -a,b +c,0 @@ — только удаление
      elseif old_count > new_count then
        kind = "changedelete" -- изменение + часть строк удалена
      else
        kind = "change"
      end
      cur = {
        kind = kind, new_start = new_start, new_count = new_count,
        old_lines = {}, new_lines = {},
      }
      hunks[#hunks + 1] = cur
    elseif cur then
      -- тело ханка; пропускаем file-хедеры (---/+++) и '\ No newline...'
      local c = line:sub(1, 1)
      if c == "-" and line:sub(1, 3) ~= "---" then
        cur.old_lines[#cur.old_lines + 1] = line:sub(2)
      elseif c == "+" and line:sub(1, 3) ~= "+++" then
        cur.new_lines[#cur.new_lines + 1] = line:sub(2)
      end
    end
  end
  return hunks
end

local function place_signs(bufnr, hunks)
  vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
  local n = vim.api.nvim_buf_line_count(bufnr)
  local function put(lnum, sign)
    if lnum >= 1 and lnum <= n then
      vim.api.nvim_buf_set_extmark(bufnr, ns, lnum - 1, 0, {
        sign_text = sign.text,
        sign_hl_group = sign.hl,
        priority = 6,
      })
    end
  end
  for _, h in ipairs(hunks) do
    if h.kind == "delete" then
      -- new_start == 0 → удалено в начале файла (знак сверху 1-й строки)
      local sign = (h.new_start == 0) and config.signs.topdelete or config.signs.delete
      put(math.max(h.new_start, 1), sign)
    else
      local sign = config.signs[h.kind]
      for l = h.new_start, h.new_start + h.new_count - 1 do
        put(l, sign)
      end
    end
  end
  if config.auto_signcolumn and #hunks > 0 then
    local win = vim.fn.bufwinid(bufnr)
    if win ~= -1 and vim.wo[win].signcolumn == "no" then
      vim.wo[win].signcolumn = "yes"
    end
  end
end

-- Строка-«якорь» ханка в новом файле (для навигации).
local function anchor_of(h)
  return (h.kind == "delete") and math.max(h.new_start, 1) or h.new_start
end

-- Ханк под данной строкой (для превью).
local function hunk_at(hunks, line)
  for _, h in ipairs(hunks) do
    if h.kind == "delete" then
      if anchor_of(h) == line then return h end
    elseif line >= h.new_start and line <= h.new_start + h.new_count - 1 then
      return h
    end
  end
  return nil
end

-- ── Навигация ────────────────────────────────────────────────────────────
local function jump(hunks, forward)
  if not hunks or #hunks == 0 then
    return vim.notify("arc-signs: изменений нет", vim.log.levels.INFO)
  end
  local anchors = {}
  for _, h in ipairs(hunks) do anchors[#anchors + 1] = anchor_of(h) end
  table.sort(anchors)
  local cur = vim.api.nvim_win_get_cursor(0)[1]
  local target
  if forward then
    for _, l in ipairs(anchors) do if l > cur then target = l break end end
    target = target or anchors[1] -- wrap на начало
  else
    for i = #anchors, 1, -1 do if anchors[i] < cur then target = anchors[i] break end end
    target = target or anchors[#anchors] -- wrap на конец
  end
  vim.api.nvim_win_set_cursor(0, { target, 0 })
  vim.cmd("normal! zz")
end

function M.next_hunk() jump(state[vim.api.nvim_get_current_buf()], true) end
function M.prev_hunk() jump(state[vim.api.nvim_get_current_buf()], false) end

-- ── Превью ───────────────────────────────────────────────────────────────
function M.preview_hunk()
  local bufnr = vim.api.nvim_get_current_buf()
  local hunks = state[bufnr]
  if not hunks then
    return vim.notify("arc-signs: нет данных, попробуй :ArcSignsRefresh", vim.log.levels.INFO)
  end
  local cur = vim.api.nvim_win_get_cursor(0)[1]
  local h = hunk_at(hunks, cur)
  if not h then
    return vim.notify("arc-signs: под курсором нет изменений", vim.log.levels.INFO)
  end

  local lines, groups = {}, {}
  for _, l in ipairs(h.old_lines) do
    lines[#lines + 1] = "-" .. l ; groups[#lines] = "DiffDelete"
  end
  for _, l in ipairs(h.new_lines) do
    lines[#lines + 1] = "+" .. l ; groups[#lines] = "DiffAdd"
  end
  if #lines == 0 then lines = { "(пусто)" } end

  local width = 1
  for _, l in ipairs(lines) do width = math.max(width, vim.fn.strdisplaywidth(l)) end
  width = math.min(math.max(width, 20), 100)
  local height = math.min(#lines, 20)

  local pbuf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(pbuf, 0, -1, false, lines)
  for i, g in pairs(groups) do
    vim.api.nvim_buf_set_extmark(pbuf, ns_preview, i - 1, 0, { line_hl_group = g })
  end
  vim.bo[pbuf].modifiable = false
  vim.bo[pbuf].filetype = "diff"

  local win = vim.api.nvim_open_win(pbuf, false, {
    relative = "cursor", row = 1, col = 0,
    width = width, height = height,
    style = "minimal", border = "rounded",
  })
  -- закрыть при движении курсора или уходе из окна
  vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI", "BufLeave", "InsertEnter" }, {
    once = true,
    callback = function()
      if vim.api.nvim_win_is_valid(win) then vim.api.nvim_win_close(win, true) end
    end,
  })
end

-- ── Буфер-локальные маппинги ───────────────────────────────────────────────
local function set_keymaps(bufnr)
  if not config.keymaps or vim.b[bufnr].arc_signs_maps then return end
  vim.b[bufnr].arc_signs_maps = true
  local function m(lhs, fn, desc)
    vim.keymap.set("n", lhs, fn, { buffer = bufnr, silent = true, desc = desc })
  end
  m("]c", M.next_hunk, "arc: следующий ханк")
  m("[c", M.prev_hunk, "arc: предыдущий ханк")
  m("<leader>gd", M.preview_hunk, "arc: превью ханка")
end

-- ── Основной пересчёт ──────────────────────────────────────────────────────
function M.refresh(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  if not buf_valid(bufnr) then return end
  local file = file_of(bufnr)
  if not file then return end
  local root = arcadia_root(file)
  if not root then return end -- не в Аркадии — не трогаем (там работает gitsigns)

  set_keymaps(bufnr)

  vim.system(
    { "arc", "diff", "--git", "-U0", "--", file },
    { cwd = vim.fs.dirname(file), text = true },
    function(res)
      vim.schedule(function()
        if not vim.api.nvim_buf_is_valid(bufnr) then return end
        local out = res.stdout or ""
        if out == "" then -- нет изменений либо ошибка → снять знаки
          vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
          state[bufnr] = {}
          return
        end
        local hunks = parse(out)
        state[bufnr] = hunks
        place_signs(bufnr, hunks)
      end)
    end
  )
end

local function schedule_refresh(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local t = timers[bufnr]
  if t then t:stop() ; t:close() end
  local timer = vim.uv.new_timer()
  timers[bufnr] = timer
  timer:start(config.debounce, 0, function()
    timer:stop() ; timer:close() ; timers[bufnr] = nil
    vim.schedule(function() M.refresh(bufnr) end)
  end)
end

function M.setup(opts)
  config = vim.tbl_deep_extend("force", config, opts or {})
  define_highlights()

  local grp = vim.api.nvim_create_augroup("ArcSigns", { clear = true })
  vim.api.nvim_create_autocmd(config.events, {
    group = grp,
    callback = function(a) schedule_refresh(a.buf) end,
  })
  vim.api.nvim_create_autocmd("ColorScheme", {
    group = grp,
    callback = define_highlights,
  })
  vim.api.nvim_create_autocmd("BufDelete", {
    group = grp,
    callback = function(a)
      local t = timers[a.buf]
      if t then t:stop() ; t:close() ; timers[a.buf] = nil end
      state[a.buf] = nil
    end,
  })

  vim.api.nvim_create_user_command("ArcSignsRefresh", function() M.refresh() end, {})
  vim.api.nvim_create_user_command("ArcSignsClear", function()
    vim.api.nvim_buf_clear_namespace(0, ns, 0, -1)
  end, {})
  vim.api.nvim_create_user_command("ArcSignsPreview", M.preview_hunk, {})
  vim.api.nvim_create_user_command("ArcSignsNext", M.next_hunk, {})
  vim.api.nvim_create_user_command("ArcSignsPrev", M.prev_hunk, {})

  vim.api.nvim_create_user_command("ArcSignsDebug", function()
    local bufnr = vim.api.nvim_get_current_buf()
    local file = vim.api.nvim_buf_get_name(bufnr)
    local root = (file ~= "") and vim.fs.root(file, { ".arcadia.root" }) or nil
    local L = {
      "arc-signs debug:",
      "  file        = " .. (file == "" and "<no name>" or file),
      "  buftype     = [" .. vim.bo[bufnr].buftype .. "]",
      "  readable    = " .. tostring(file ~= "" and vim.fn.filereadable(file) == 1),
      "  arc bin     = " .. (vim.fn.exepath("arc") == "" and "!! НЕ найден в PATH" or vim.fn.exepath("arc")),
      "  arcadia root= " .. tostring(root),
      "  signcolumn  = " .. vim.wo.signcolumn,
      "  cached hunks= " .. tostring(state[bufnr] and #state[bufnr] or "nil"),
    }
    if file ~= "" and vim.fn.filereadable(file) == 1 and root then
      local r = vim.system({ "arc", "diff", "--git", "-U0", "--", file },
        { cwd = vim.fs.dirname(file), text = true }):wait()
      L[#L + 1] = "  arc exit    = " .. tostring(r.code)
      L[#L + 1] = "  stdout len  = " .. #(r.stdout or "")
      L[#L + 1] = "  stderr      = " .. ((r.stderr or ""):gsub("%s+$", ""))
    else
      L[#L + 1] = "  arc НЕ запускался (нет root / файл не читается)"
    end
    vim.notify(table.concat(L, "\n"), vim.log.levels.INFO)
  end, {})

  schedule_refresh() -- первичный проход по уже открытому буферу
end

return M
