return {
  'rcarriga/nvim-notify',
  config = function()
    require('notify').setup({
      stages = 'fade',       -- анимация: fade/slide/static
      timeout = 3000,
      max_width = 50,
      icons = {
        ERROR = '',
        WARN  = '',
        INFO  = '',
        DEBUG = '',
        TRACE = '✎',
      },
    })
    vim.notify = require('notify')  -- подключаем
  end
}
