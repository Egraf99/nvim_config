vim.keymap.set("n", "<C-T><C-T>", function()
    vim.cmd([[ToggleTerm direction=float]])
end)

vim.keymap.set("n", "<C-T><C-H>", function()
    vim.cmd([[ToggleTerm direction=horizontal]])
end)

vim.keymap.set("n", "<C-T><C-J>", function()
    vim.cmd([[ToggleTerm direction=vertical]])
end)

return {
    {
        'akinsho/toggleterm.nvim', version = "*",
        opts = {
            autochdir = true,
            size = function(term)
                if term.direction == "horizontal" then
                  return 15
                elseif term.direction == "vertical" then
                  return vim.o.columns * 0.4
                end
            end,
        }
    }
}
