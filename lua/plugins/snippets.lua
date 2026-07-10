return {
    {
        "L3MON4D3/LuaSnip",
        run = "make install_jsregexp",
        config = function ()
            require("luasnip.loaders.from_lua").load({paths = "~/.config/nvim/snippets"})

            local ls = require("luasnip")

            -- vim.keymap.set({"i"}, "<C-L>", function() ls.expand() end, {silent = true})
            vim.keymap.set({"i"}, "<C-L>", function() ls.jump( 1) end, {silent = true})
            vim.keymap.set({"i"}, "<C-U>", function() ls.jump(-1) end, {silent = true})
            --
            vim.keymap.set({"i"}, "<C-J>", function()
                if ls.choice_active() then ls.change_choice(1) end
            end, {silent = false})
------- crash TAB !
        end
    }
}
