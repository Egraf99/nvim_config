return {
    'nvim-lualine/lualine.nvim',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    config = function ()
        -- Ветка Arc (VCS Аркадии). arc info опрашиваем асинхронно через vim.system,
        -- чтобы не блокировать отрисовку статуслайна, и кешируем результат.
        -- Обновляем по автокомандам ниже. Пустая строка => не arc-репозиторий.
        local arc_cache = ''

        local function arc_update()
            local dir = vim.fn.expand('%:p:h')
            if dir == '' then
                dir = vim.fn.getcwd()
            end
            vim.system(
                { 'arc', 'info', '--json' },
                { cwd = dir, text = true },
                vim.schedule_wrap(function(res)
                    local branch = ''
                    if res.code == 0 and res.stdout ~= '' then
                        local ok, info = pcall(vim.json.decode, res.stdout)
                        if ok and type(info) == 'table' and info.branch then
                            branch = info.branch
                        end
                    end
                    if branch ~= arc_cache then
                        arc_cache = branch
                        vim.cmd('redrawstatus')
                    end
                end)
            )
        end

        vim.api.nvim_create_autocmd({ 'BufEnter', 'FocusGained', 'DirChanged', 'BufWritePost' }, {
            callback = arc_update,
        })

        local function arc_branch()
            if arc_cache == '' then
                return ''
            end
            return ' ' .. arc_cache
        end

        -- Состояние molten-nvim ведём сами, по его событиям (User MoltenInitPost /
        -- MoltenKernelReady / MoltenDeinitPost). На vim.fn.Molten* не опираемся:
        -- в связке remote-плагина с lazy.nvim эти функции в сессии не регистрируются
        -- (exists('*MoltenStatusLineInit') == 0), поэтому статус всегда был пустым.
        local molten_bufs = {} -- bufnr -> { ready = bool, kernel = string }
        local molten_state = 'off' -- вычисляется в molten_status(), используется в molten_color()

        vim.api.nvim_create_autocmd('User', {
            pattern = 'MoltenInitPost',
            callback = function(a)
                local b = a.buf or vim.api.nvim_get_current_buf()
                molten_bufs[b] = molten_bufs[b] or { ready = false }
                vim.cmd('redrawstatus')
            end,
        })
        vim.api.nvim_create_autocmd('User', {
            pattern = 'MoltenKernelReady',
            callback = function(a)
                local b = a.buf or vim.api.nvim_get_current_buf()
                local kid = a.data and (a.data.kernel_id or a.data.kernel) or nil
                molten_bufs[b] = { ready = true, kernel = kid }
                vim.cmd('redrawstatus')
            end,
        })
        vim.api.nvim_create_autocmd('User', {
            pattern = 'MoltenDeinitPost',
            callback = function(a)
                molten_bufs[a.buf or vim.api.nvim_get_current_buf()] = nil
                vim.cmd('redrawstatus')
            end,
        })
        vim.api.nvim_create_autocmd({ 'BufDelete', 'BufWipeout' }, {
            callback = function(a) molten_bufs[a.buf] = nil end,
        })

        local function molten_status()
            if vim.bo.filetype ~= 'python' then
                molten_state = 'off'
                return ''
            end
            local s = molten_bufs[vim.api.nvim_get_current_buf()]
            if not s then
                molten_state = 'off'
                return '󰀓 off'
            end
            if s.ready then
                molten_state = 'on'
                return '󰀓 ' .. (s.kernel or 'ready')
            end
            molten_state = 'idle' -- инициализирован, ядро ещё подключается
            return '󰀓 …'
        end

        local function molten_color()
            if molten_state == 'on' then
                return { fg = '#4caf50' } -- ядро подключено
            elseif molten_state == 'idle' then
                return { fg = '#e0a000' } -- подключается
            end
            return { fg = '#888888' }     -- выключено
        end

        require('lualine').setup {
            options = {
                theme = 'ayu_light',
            },
            sections = {
                lualine_b = { arc_branch, 'diagnostics' },
                lualine_x = {
                    { molten_status, color = molten_color },
                    'encoding', 'fileformat', 'filetype',
                },
            },
        }
    end
}
