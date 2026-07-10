local function set_custom_command()

    vim.api.nvim_create_user_command( 'Tconfig',    function () require('telescope.builtin').find_files({cwd="~/.config/nvim"}) end, {} )
    vim.api.nvim_create_user_command( 'TGconfig',   function () require('telescope.builtin').live_grep({cwd= "~/.config/nvim"}) end, {} )

    vim.api.nvim_create_user_command( 'Thrdwh',     function () require('telescope.builtin').find_files({cwd="~/arcadia/intranet/hrdwh/etl"}) end, {} )
    vim.api.nvim_create_user_command( 'TGhrdwh',    function () require('telescope.builtin').live_grep({cwd= "~/arcadia/intranet/hrdwh/etl"}) end, {} )

    vim.api.nvim_create_user_command( 'Tlogos',     function () require('telescope.builtin').find_files({cwd="~/arcadia/logos", search_dirs={"logs/hrdwh", "logs/md_schema/hrdwh", "projects/hrdwh"}}) end, {} )
    vim.api.nvim_create_user_command( 'TGlogos',    function () require('telescope.builtin').live_grep({cwd= "~/arcadia/logos"}) end, {} )

    vim.api.nvim_create_user_command( 'Tlib',       function () require('telescope.builtin').find_files({cwd="~/arcadia/intranet/hrdwh/library"}) end, {} )
    vim.api.nvim_create_user_command( 'TGlib',      function () require('telescope.builtin').live_grep({cwd= "~/arcadia/intranet/hrdwh/library"}) end, {} )

    vim.api.nvim_create_user_command( 'Tdmp',       function () require('telescope.builtin').find_files({cwd="~/arcadia/taxi/dmp/dwh/services/hr_etl"}) end, {} )
    vim.api.nvim_create_user_command( 'TGdmp',      function () require('telescope.builtin').live_grep({cwd= "~/arcadia/taxi/dmp/dwh/services/hr_etl"}) end, {} )

    vim.api.nvim_create_user_command( 'Thelp',      function () require('telescope.builtin').help_tags() end, {} )

    vim.api.nvim_create_user_command( 'Tbuffers',   function () require('telescope.builtin').buffers() end, {} )

end


local function set_keymaps()
    local map = vim.keymap

    map.set("n", "<leader>ff", ":Telescope current_buffer_fuzzy_find<CR>")
    map.set("n", "<leader>fs", ":Telescope arc status<CR>")

    map.set("n", "<leader>fd", ":Thrdwh<CR>")
    map.set("n", "<leader>fgd", ":TGhrdwh<CR>")

    map.set("n", "<leader>fc", ":Tconfig<CR>")
    map.set("n", "<leader>fgc", ":TGconfig<CR>")

    map.set("n", "<leader>fl", ":Tlogos<CR>")
    map.set("n", "<leader>fgl", ":TGlogos<CR>")

    map.set("n", "<leader>fi", ":Tlib<CR>")
    map.set("n", "<leader>fgi", ":TGlib<CR>")

    map.set("n", "<leader>fm", ":Tdmp<CR>")
    map.set("n", "<leader>fgm", ":TGdmp<CR>")

    map.set("n", "<leader>fh", ":Thelp<CR>")
    map.set("n", "<leader>fgh", ":TGhelp<CR>")

    map.set("n", "<leader>fb", ":Tbuffers<CR>")
    map.set("n", "<leader>fq", ":Telescope quickfix<CR>")
end



return {
    'tetzng/telescope-cica-icons.nvim',
    { 'nvim-tree/nvim-web-devicons', opts = {} },
    {
        'nvim-telescope/telescope.nvim',
        branch = '0.1.x',
        dependencies = {
            'nvim-lua/plenary.nvim',
            'tetzng/telescope-cica-icons.nvim',
            {
              dir = "/home/khodinegor/arcadia/junk/moonw1nd/lua/telescope-arc.nvim",
              name = "telescope-arc",
            },
        },
        config = function ()
            require('telescope').setup({
                defaults = {
                    path_display = {
                        truncate = 5
                    },
                    wrap_results = true,  -- перенос длинных строк
                    scroll_offset = 5,  -- отступ сверху и снизу от выбранной строки
                }

            })

            require('telescope').load_extension('cica_icons')
            require('telescope').load_extension('arc')

            set_custom_command()
            set_keymaps()

        end
    }
}
