vim.opt.number           = true
vim.opt.relativenumber   = true

vim.opt.scrolloff         = 20
vim.opt.sidescrolloff     = 5

vim.opt.mouse         = "a"
vim.opt.mousehide     = true

vim.opt.tabstop       = 4
vim.opt.shiftwidth    = 4
vim.opt.smarttab      = true
vim.opt.expandtab     = true
vim.opt.smartindent   = true
vim.opt.autoindent    = true

vim.opt.wrap = false

-- Popup меню при автодополнении (почему-то не работает, разобраться)
-- vim.g.completeopt = { "longest", "menuone" } --"menuone" --"menu" -- "menuone", "longest"
-- vim.cmd [[set completeopt=longest,menuone]]
vim.opt.pumheight = 10


vim.api.nvim_create_autocmd({"BufEnter", "BufNew"}, {
    pattern = {"*"},
    callback = function()
        if vim.o.buftype == '' then
            vim.cmd [[:cd %:p:h]]
        end
    end,
})

-- Подсвечивать слова только при поиске
vim.cmd [[
    augroup vimrc-incsearch-highlight
      autocmd!
      autocmd CmdlineEnter /,\? :set hlsearch
      autocmd CmdlineLeave /,\? :set nohlsearch
    augroup END
]]
vim.keymap.set("n", "<C-n>", [[:nohlsearch<CR>]])


-- Работа с кирилицей (для переключения между языками: <C-^>
-- vim.opt.spelllang  = "en,ru"
-- vim.opt.keymap     = "russian-jcukenwin"
-- vim.opt.iminsert   = 0
-- vim.opt.imsearch   = 0
-- vim.opt.encoding   = "UTF-8"


-- Переключаться на правый/нижний буфер при split
vim.opt.splitright = true
vim.opt.splitbelow = true

-- Копировать в буфер обмена при любой операции
vim.opt.clipboard = vim.opt.clipboard + "unnamedplus"

-- Не автокомментировать новые линии при переходе на новую строку
vim.cmd [[autocmd BufEnter * set fo-=c fo-=r fo-=o]]

vim.g.mapleader = " "
-- Выход из TERMINAL режима
vim.keymap.set("t", "<C-[>", [[<C-\><C-n>]])
vim.keymap.set("t", "<Esc>", [[<C-\><C-n>]])

vim.keymap.set({"n", "v", "o"}, "H", "^")
vim.keymap.set({"n", "v", "o"}, "L", "$")

vim.keymap.set("n", "<leader>w", "<C-w>")

vim.keymap.set("n", "<leader>bo", ":%bd|e#<CR>")

-- move to neotree.lua
-- vim.keymap.set("n", "<leader>n", ":e %:p:h<CR>")
-- vim.keymap.set("n", "<leader>n", ":Neotree %:p:h<CR>")


-- подсвечивать скопированный текст 200 ms
vim.cmd [[autocmd TextYankPost * silent! lua vim.hl.on_yank {higroup='Visual', timeout=200}]]


-- Show errors and warnings in a floating window
vim.keymap.set("n", "<C-j>", function()
    vim.diagnostic.open_float(nil, { focusable = false, source = "if_many" })
end)


-- Netrw
vim.g.netrw_banner=0 -- скрыть баннер
vim.g.netrw_liststyle=3 -- показывать дерево


vim.opt.gdefault = true

vim.keymap.set({"n"}, "<C-r>", [["]])
vim.keymap.set({"n"}, "U", "<C-r>")


vim.opt.formatprg = "lua ~/dev/sqllinter/linter.lua"

vim.g.current_colorscheme = "alabaster-bg"

vim.api.nvim_set_hl(0, "MoltenCell", { link = "" })
