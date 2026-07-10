return {
    'nvim-lualine/lualine.nvim',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    config = function ()
	-- not work
        local function arc_branch()
            return os.execute([[arc info --json | grep -Po '"branch":.*?[^\\]",' | perl -pe 's/"branch"://; s/^"//; s/",$//']])
        end

        require('lualine').setup {
            options = {
                theme = 'ayu_light',
            },
            -- sections = { lualine_b = {vim.cmd[[!arc info --json | grep -Po '"branch":.*?[^\\]",' | perl -pe 's/"branch"://; s/^"//; s/",$//']]} }
        }
    end
    -- arc info --json | grep -Po '"branch":.*?[^\\]",' | perl -pe 's/"branch"://; s/^"//; s/",$//'
    -- os.execute ()
}
