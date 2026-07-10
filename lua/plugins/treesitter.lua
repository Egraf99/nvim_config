return {
    'nvim-treesitter/nvim-treesitter',
    run = ':TSUpdate',
    config = function()
        vim.treesitter.language.add('python', { path = "/home/khodinegor/dev/sqllinter/python.so" })
        vim.treesitter.language.add('sql', { path = "/home/khodinegor/dev/sqllinter/sql.so" })
        require("nvim-treesitter.configs").setup({
            highlight = {
                enable = true
            }
        })

        -- vim.cmd [[hi link @warning.lowercase.sql DiagnosticUnderLineError]]
        -- vim.cmd [[hi link @warning.commaEnd.sql Error]]
    end
}
