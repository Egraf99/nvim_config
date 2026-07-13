return {
    'segoon/goto-arcanum.nvim',

    -- Локальный плагин: gutter-знаки изменений относительно arc HEAD.
    {
        dir = vim.fn.stdpath("config") .. "/arc-signs.nvim",
        name = "arc-signs",
        event = { "BufReadPost", "BufNewFile" },
        config = function()
            require("arc-signs").setup({
                -- debounce = 250,
                -- auto_signcolumn = true,
                -- signs = { add = { text = "┃", hl = "ArcSignsAdd" }, ... },
            })
        end,
    },
}
