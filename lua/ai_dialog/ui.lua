-- ~/.config/nvim/lua/ai_dialog/ui.lua

local M = {}
project = require("ai_dialog.project")
local core = require("ai_dialog.core")

---创建浮动窗口和 buffer
function M.create()
  local buf = vim.api.nvim_create_buf(false, true) -- 临时 buffer
  -- core.start_auto_render_timer(buf)
  if not buf then
    vim.notify("Failed to create buffer", vim.log.levels.ERROR)
    return
  end
  core.attach_autorender(buf)

  local width = math.min(vim.o.columns * 0.8, 100)
  local height = math.min(vim.o.lines * 0.6, 30)

  local win = vim.api.nvim_open_win(buf, false, {
    relative = "editor",
    width = width,
    height = height,
    col = (vim.o.columns - width) / 2,
    row = (vim.o.lines - height) / 2,
    style = "minimal",
    border = "rounded",
    title = " AI Assistant ",
    title_pos = "left",
  })

  -- 设置 buffer 属性
  vim.api.nvim_buf_set_option(buf, "bufhidden", "hide")
  vim.api.nvim_buf_set_option(buf, "buftype", "nofile")
  vim.api.nvim_buf_set_option(buf, "swapfile", false)
  -- 设置 buffer 支持写入和保存
  vim.api.nvim_buf_set_option(buf, "modifiable", true)
  vim.api.nvim_buf_set_option(buf, "filetype", "markdown")

  vim.api.nvim_set_current_win(win) -- 自动 focus 浮窗窗口

  -- 添加q键关闭窗口的绑定
  vim.keymap.set("n", "q", function()
    pcall(vim.api.nvim_win_close, win, true)
  end, { buffer = buf, silent = true })
  vim.keymap.set("n", "w", function()
    project.save_current_dialog()
  end, { buffer = buf, silent = true })

  return { buf = buf, win = win }
end

return M
