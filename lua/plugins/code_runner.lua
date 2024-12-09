return {
  "CRAG666/code_runner.nvim",
  dependencies = { "nvim-lua/plenary.nvim" },
  config = function()
    require("code_runner").setup({
      filetype = {
        python = "python3 -u",
        go = "go run",
        javascript = "node",
        -- 其他语言的配置
      },
      mode = "float",
      float = {
        border = "rounded",
        highlight = "Normal",
        border_hl = "FloatBorder",
      },
    })
  end,
}
