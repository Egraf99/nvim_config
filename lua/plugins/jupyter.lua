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
        build = ":UpdateRemotePlugins",
        init = function()
            local kernel = 'hrdwh-spyt'

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
}
