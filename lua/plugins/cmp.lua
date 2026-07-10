vim.g.cmp_enabled = true

local function enable_cmp()
  vim.g.cmp_enabled = true

  local cmp = require("cmp")

  -- Переустанавливаем маппинг вручную
  vim.keymap.set('i', '<Tab>', function()
    if cmp.visible() and cmp.get_selected_entry() then
      cmp.confirm({ select = true })
    else
      vim.api.nvim_feedkeys(
        vim.api.nvim_replace_termcodes('<Tab>', true, false, true),
        'n', false
      )
    end
  end, { buffer = 0 })
end

local function disable_cmp()
  vim.g.cmp_enabled = false
  require("cmp").close()

  -- Восстанавливаем обычный Enter
  pcall(vim.keymap.del, 'i', '<Tab>', { buffer = 0 })
end

vim.keymap.set({'i', 'n'}, '<C-space>', function()
    if not vim.g.cmp_enabled then
        enable_cmp()
    else
        disable_cmp()
    end
    vim.notify(
        'nvim-cmp: ' .. (vim.g.cmp_enabled and 'ON' or 'OFF')
    )
end)

return {
    'neovim/nvim-lspconfig',
    'hrsh7th/cmp-nvim-lsp',
    'hrsh7th/cmp-buffer',
    'hrsh7th/cmp-path',
    'hrsh7th/cmp-cmdline',
    'saadparwaiz1/cmp_luasnip',
    {
        'hrsh7th/nvim-cmp',
        config = function()
            -- Set up nvim-cmp.
            local cmp = require('cmp')

            cmp.setup({
                completion = {
                    completeopt = 'menu,menuone,longest,noinsert',  -- автовыбор первого
                },
                preselect = cmp.PreselectMode.Item,
                enabled = function()
                    local filetype = vim.bo.filetype  -- короткий 

                    local disabled_filetypes = {
                      'TelescopePrompt',
                      'neo-tree',
                      'lazy',
                    }

                    if vim.tbl_contains(disabled_filetypes, filetype) then
                      return false
                    end

                    return vim.g.cmp_enabled
                end,
                snippet = {
                    expand = function(args)
                        require('luasnip').lsp_expand(args.body) -- For `luasnip` users.
                    end,
                },
                window = {
                    completion = { border = 'rounded' },
                    documentation = { border = 'rounded' }
                },
                mapping = cmp.mapping.preset.insert({
                  ['<C-b>'] = cmp.mapping.scroll_docs(-4),
                  ['<C-f>'] = cmp.mapping.scroll_docs(4),
                  ['<C-j>'] = cmp.mapping.select_next_item({behavior = cmp.SelectBehavior.Select}),
                  ['<C-k>'] = cmp.mapping.select_prev_item({behavior = cmp.SelectBehavior.Select}),
                  ['<Tab>'] = cmp.mapping.confirm({ select = true }),
                }),
                sources = cmp.config.sources({
                    { name = 'luasnip', priority = 99 },
                    { name = 'nvim_lsp', priority = 98 },
                }, {
                    { name = 'buffer' },
                })
            })

            -- Use buffer source for `/` and `?` (if you enabled `native_menu`, this won't work anymore).
            cmp.setup.cmdline({ '/', '?' }, {
                enabled = true,
                mapping = cmp.mapping.preset.cmdline(),
                sources = {
                  { name = 'buffer' }
                }
            })

            -- Use cmdline & path source for ':' (if you enabled `native_menu`, this won't work anymore).
            cmp.setup.cmdline(':', {
                enabled = true,
                mapping = cmp.mapping.preset.cmdline(),
                sources = cmp.config.sources({
                  { name = 'path' }
                }, {
                  { name = 'cmdline' }
                }),
                matching = { disallow_symbol_nonprefix_matching = false }
            })

            -- Set up lspconfig.
            local capabilities = require('cmp_nvim_lsp').default_capabilities()
            vim.lsp.enable('pyright', {
                capabilities = capabilities
            })
        end
    }

}
