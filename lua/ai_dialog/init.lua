print("init my lua")

local M = {}
local function safe_require(module)
  local ok, mod = pcall(require, module)
  if not ok then
    vim.notify("Failed to load module " .. module, vim.log.levels.ERROR)
    return nil
  end
  return mod
end

local buf = safe_require("ai_dialog.buffer")
if buf then
  function M.toggle()
    buf.toggle()
  end
end

local core = safe_require("ai_dialog.core")
if core then
  function M.chat()
    core.safe_chat()
  end
  function M.reload()
    local project = safe_require("ai_dialog.project")
    if not project then return end
    local dialog = project.get_current_dialog()
    if dialog and dialog.buf then
      vim.api.nvim_buf_set_option(dialog.buf, 'modifiable', true)
      local _, rendered = core.parse_buffer_structured(dialog.buf)
      -- 拆分所有带\n的元素为多行
      local flat = {}
      for _, l in ipairs(rendered) do
        if l:find("\n") then
          for _, sub in ipairs(vim.split(l, "\n", true)) do table.insert(flat, sub) end
        else
          table.insert(flat, l)
        end
      end
      vim.api.nvim_buf_set_lines(dialog.buf, 0, -1, false, flat)
    end
  end
end

-- 在对话缓冲区中设置回车键映射
vim.api.nvim_create_autocmd("BufEnter", {
  pattern = "*",
  callback = function()
    -- 只在对话缓冲区中设置映射
    local buf = vim.api.nvim_get_current_buf()
    local buf_name = vim.api.nvim_buf_get_name(buf)
    
    -- 打印调试信息
    print("BufEnter triggered for buffer:", buf, "name:", buf_name)
    
    -- 检查是否为对话缓冲区：使用最可靠的方法
    local is_dialog_buffer = false
    
    -- 方法1：通过项目模块检查当前对话缓冲区
    local project = require("ai_dialog.project")
    local current_dialog = project.get_current_dialog()
    if current_dialog and current_dialog.buf == buf then
      is_dialog_buffer = true
      print("Buffer identified as dialog buffer via project check")
    else
      -- 方法2：检查缓冲区选项，如果是临时缓冲区且设置了特定标志，则可能是对话缓冲区
      local buftype = vim.api.nvim_buf_get_option(buf, "buftype")
      local filetype = vim.api.nvim_buf_get_option(buf, "filetype")
      print("Buffer buftype:", buftype, "filetype:", filetype)
      if buftype == "nofile" and filetype == "markdown" then
        is_dialog_buffer = true
        print("Buffer identified as dialog buffer via buftype/filetype check")
      end
    end
    
    if is_dialog_buffer then
      print("Setting keymap for dialog buffer")
      -- 使用一个更简单直接的方案：设置一个全局函数来控制回车键
      -- 该函数会检查当前项目是否正在生成回复
      vim.api.nvim_buf_set_keymap(buf, "i", "<CR>", [[<Cmd>lua require('ai_dialog.core').safe_chat()<CR>]], { noremap = true, silent = true })
    else
      print("Not a dialog buffer, skipping keymap setting")
    end
  end
})

vim.api.nvim_create_user_command("AIToggle", function()
  if M.toggle then M.toggle() end
end, {})

vim.api.nvim_create_user_command("AIChat", function()
  if M.chat then M.chat() end
end, {})

vim.api.nvim_create_user_command("AIReload", function()
  if M.reload then M.reload() end
end, {})

-- 添加调试命令
vim.api.nvim_create_user_command("AIDebugDialog", function()
  local project = require("ai_dialog.project")
  local dialog = project.get_current_dialog()
  if dialog then
    print("Current dialog buffer:", dialog.buf)
    print("Buffer valid:", vim.api.nvim_buf_is_valid(dialog.buf))
    local buftype = vim.api.nvim_buf_get_option(dialog.buf, "buftype")
    local filetype = vim.api.nvim_buf_get_option(dialog.buf, "filetype")
    print("Dialog buffer buftype:", buftype, "filetype:", filetype)
  else
    print("No current dialog")
  end
end, {})

return M
