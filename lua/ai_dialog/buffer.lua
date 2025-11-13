-- lua/ai_dialog/buffer.lua
local vim = vim -- Declare vim to satisfy linter
local project = require("ai_dialog.project")
local project_root = project.get_project_root()
local project_name = vim.fn.fnamemodify(project_root, ":t")
local ui = require("ai_dialog.ui")
local render = require("ai_dialog.render")

local M = {}
local timer = nil

local function update_time(dialog)
  local buf, win = dialog.buf, dialog.win
  local now = os.date("### 当前时间：%Y-%m-%d %H:%M:%S")
  -- print("Updating time:", vim.inspect(now))
  vim.schedule(function()
    if vim.api.nvim_buf_is_valid(buf) then
      vim.api.nvim_buf_set_lines(buf, 0, 1, false, { now })
      if win and vim.api.nvim_win_is_valid(win) then
        vim.api.nvim_win_call(win, function()
          vim.cmd("redraw")
        end)
      end
    end
  end)
end

function M.start_time_render(dialog)
  if dialog.timer then
    dialog.timer:stop()
    dialog.timer:close()
    dialog.timer = nil
  end
  update_time(dialog)
  dialog.timer = vim.loop.new_timer()
  dialog.timer:start(
    0,
    2000,
    vim.schedule_wrap(function()
      update_time(dialog)
    end)
  )
end

function M.stop_time_render(dialog)
  if dialog and dialog.timer then
    dialog.timer:stop()
    dialog.timer:close()
    dialog.timer = nil
  end
end

function M.toggle()
  local current_dialog = project.get_current_dialog()

  if current_dialog and vim.api.nvim_win_is_valid(current_dialog.win) then
    -- 窗口已存在，关闭它
    pcall(vim.api.nvim_win_close, current_dialog.win, false)
    -- 不再自动清理历史消息
    -- project.clear_current_dialog()
    M.stop_time_render(current_dialog)
  else
    -- 创建新窗口
    project.ensure_cache_dir()

    local dialog = ui.create()
    if dialog then
      -- 存储项目对话状态
      project.set_current_dialog(dialog)
      local core = require("ai_dialog.core")
      local project_name = vim.fn.fnamemodify(project.get_project_root(), ":t")
      -- 仅在没有缓存时初始化内容
      local cache_path = project.get_dialog_path()
      if vim.fn.filereadable(cache_path) == 1 then
        local lines = vim.fn.readfile(cache_path)
        vim.api.nvim_buf_set_lines(dialog.buf, 0, -1, false, lines)
      else
        core.init_buffer(dialog.buf, project_name)
      end
    end
  end
end

function M.test_render()
  local render = require("ai_dialog.render")
  local buf = vim.api.nvim_create_buf(false, true)
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = 60,
    height = 10,
    col = 10,
    row = 5,
    style = "minimal",
    border = "single",
  })

  render.typewriter(buf, 0, "Running Typewriter effect test...", 50)
  -- 普通渲染测试（分步延时）
  render.set_line(buf, 0, "set_line: 第一行")
  vim.defer_fn(function()
    render.append_lines(buf, { "append_lines: 第二行", "append_lines: 第三行" })
    vim.defer_fn(function()
      render.insert_lines(buf, 1, { "insert_lines: 插入到第2行" })
      vim.defer_fn(function()
        render.replace(buf, { "replace: 只剩这一行" })
        vim.defer_fn(function()
          render.clear(buf)
          render.append_lines(buf, { "测试完成", "你可以关闭窗口" })
          render.ensure_visible(win, 1)
          -- 流式渲染测试（再延时1.5秒）
          vim.defer_fn(function()
            render.clear(buf)
            local lines = {
              "流式输出测试：",
              "第一行内容...",
              "第二行内容...",
              "第三行内容...",
              "流式渲染结束。",
            }
            render.stream_paragraph(buf, lines, { mode = "append", interval = 200 })
          end, 1500)
        end, 1000)
      end, 1000)
    end, 1000)
  end, 1000)
end

return M
