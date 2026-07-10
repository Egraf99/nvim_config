return {
    {
      "folke/lazydev.nvim",
      ft = "lua", -- only load on lua files
    },
    {
        "neovim/nvim-lspconfig",
        config = function()
            local capabilities = require('cmp_nvim_lsp').default_capabilities()

            vim.lsp.config('pyright', {
              capabilities = capabilities,
              settings = {
                python = {
                  analysis = {
                    autoSearchPaths = true,
                    diagnosticMode = "workspace",
                    useLibraryCodeForTypes = true,
                    reportMissingImports = false,
                    extraPaths = {
                      "/home/khodinegor/remote-venv/lib/python3.12/site-packages"
                    },
                  },
                }
              }
            })
            -- vim.lsp.enable('pyright')
            vim.lsp.enable('lua_ls', {
                on_init = function(client)
                    if client.workspace_folders then
                        local path = client.workspace_folders[1].name
                        if path ~= vim.fn.stdpath('config') and (vim.loop.fs_stat(path..'/.luarc.json') or vim.loop.fs_stat(path..'/.luarc.jsonc')) then
                            return
                        end
                    end

                    client.config.settings.Lua = vim.tbl_deep_extend('force', client.config.settings.Lua, {
                        runtime = {
                            -- Tell the language server which version of Lua you're using
                            -- (most likely LuaJIT in the case of Neovim)
                            version = 'LuaJIT'
                        },
                            -- Make the server aware of Neovim runtime files
                            workspace = {
                                checkThirdParty = false,
                                library = {
                                    vim.env.VIMRUNTIME
                                    -- Depending on the usage, you might want to add additional paths here.
                                    -- "${3rd}/luv/library"
                                    -- "${3rd}/busted/library",
                            }
                        }
                    })
                end,
                settings = {
                    Lua = { diagnostics = { globals = {'vim'} } }
                }
            })

            vim.diagnostic.config({
                virtual_text = {
                    prefix = '→ ',  -- Could be '●', '■', '▎', 'x'
                    source = 'if_many',
                },
                signs = {
                    text = {
                        [vim.diagnostic.severity.INFO] = '',
                        [vim.diagnostic.severity.HINT] = '',
                        [vim.diagnostic.severity.WARN] = '',
                        [vim.diagnostic.severity.ERROR] = '',
                    },
                    texthl = {
                        [vim.diagnostic.severity.INFO] = 'DiagnosticSignInfo',
                        [vim.diagnostic.severity.HINT] = 'DiagnosticSignHint',
                        [vim.diagnostic.severity.WARN] = 'DiagnosticSignWarn',
                        [vim.diagnostic.severity.ERROR] = 'DiagnosticSignError',
                    },
                    numhl = {
                        [vim.diagnostic.severity.INFO] = 'DiagnosticSignInfo',
                        [vim.diagnostic.severity.HINT] = 'DiagnosticSignHint',
                        [vim.diagnostic.severity.WARN] = 'DiagnosticSignWarn',
                        [vim.diagnostic.severity.ERROR] = 'DiagnosticSignError',
                    },
                },
            })

        end
    }
}
