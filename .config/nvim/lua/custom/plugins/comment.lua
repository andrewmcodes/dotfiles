-- Use gc to comment visual regions/lines
return {
  {
    "numToStr/Comment.nvim",
    opts = {
      toggler = { line = '<leader>/', block = '<leader>?' },
      opleader = { line = '<leader>/', block = '<leader>?' },
    }
  }
}
