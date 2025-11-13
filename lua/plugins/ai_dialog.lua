local ai = require("ai_dialog.init")

return {
  {
    "ai_dialog",
    dependencies = "nvim-lua/plenary.nvim",
    dir = "/Users/wonder/.config/nvim/lua/ai_dialog/",
    keys = {
      {
        "<leader>ac",
        function()
          ai.toggle()
        end,
        desc = "💬 聊天",
      },
      {
        "<leader>ar",
        function()
          ai.chat()
        end,
        desc = "✨ 发送",
      },
    },
    event = "VeryLazy",
  },
}
