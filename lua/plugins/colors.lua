return {
	{"mhartington/oceanic-next", lazy = true},
	{"ellisonleao/gruvbox.nvim", lazy = true},
    {
        dir = "/home/khodinegor/.config/nvim/lua/custom/alabaster_custom.vim",
        name = "alabaster",
        lazy = false,
        priority = 1000,
        config = function()
            vim.o.termguicolors = true
            vim.o.background = "light"
            vim.o.syntax = "enable"
            vim.cmd("colorscheme alabaster-bg")
        end,
    }
}
