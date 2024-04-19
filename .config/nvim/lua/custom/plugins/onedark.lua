return {
  {
    "olimorris/onedarkpro.nvim",
    priority = 1000, -- Ensure it loads first
    config = function()
      require("onedarkpro").setup({
        colors = {
          -- red = "#FF0000"
        }
      })

      vim.cmd("colorscheme onedark")
    end
  }
}
