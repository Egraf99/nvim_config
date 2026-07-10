return {
    'mfussenegger/nvim-lint',
    config = function ()
        local lint = require('lint')
        lint.linters_by_ft = {
          python = {
              'flake8',
          },
        }
        vim.api.nvim_create_autocmd({ "InsertLeave" }, {
          callback = function()
            require('lint').try_lint()
          end,
        })
    end
}
