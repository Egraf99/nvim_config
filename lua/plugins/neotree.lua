return {
  {{ "nvim-tree/nvim-web-devicons", opts = {} },},
  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
      "nvim-tree/nvim-web-devicons", -- optional, but recommended
    },
    lazy = false, -- neo-tree will lazily load itself
    config = {
        vim.keymap.set("n", "<leader>n", ":Neotree action=focus position=left reveal=true<CR>")
    }
  }
}


