return {
  "akinsho/toggleterm.nvim",
  version = "*",
  opts = {
    direction = "horizontal",
    size = 15,
    start_in_insert = true,
    close_on_exit = false,
  },
  keys = {
    { "<leader>tt", "<cmd>ToggleTerm<CR>", desc = "Toggle Terminal" },
  },
}
