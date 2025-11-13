-- ai_dialog/test/render_test.lua
-- 集成 render.lua 的各类渲染测试

local render = require("ai_dialog.render")
local M = {}

-- 普通渲染+流式渲染测试
function M.test_render()
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

  -- 普通渲染测试（分步延时）
  render.set_line(buf, 0, "set_line: 第一行")
  vim.defer_fn(function()
    render.append_lines(buf, {"append_lines: 第二行", "append_lines: 第三行"})
    vim.defer_fn(function()
      render.insert_lines(buf, 1, {"insert_lines: 插入到第2行"})
      vim.defer_fn(function()
        render.replace(buf, {"replace: 只剩这一行"})
        vim.defer_fn(function()
          render.clear(buf)
          render.append_lines(buf, {"测试完成", "你可以关闭窗口"})
          render.ensure_visible(win, 1)
          -- 流式渲染测试（再延时1.5秒）
          vim.defer_fn(function()
            render.clear(buf)
            local lines = {
              "流式输出测试：",
              "第一行内容...",
              "第二行内容...",
              "第三行内容...",
              "流式渲染结束。"
            }
            render.stream_paragraph(buf, lines, {mode="append", interval=200, typewriter=true, typewriter_interval=40})
          end, 1500)
        end, 1000)
      end, 1000)
    end, 1000)
  end, 1000)
end

-- README.md 流式渲染测试
function M.test_render_markdown()
  local buf = vim.api.nvim_create_buf(false, true)
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = 120,
    height = 40,
    col = 5,
    row = 2,
    style = "minimal",
    border = "single",
  })
  vim.api.nvim_buf_set_option(buf, "filetype", "markdown")
  local render = require("ai_dialog.render")
  local uv = vim.loop
  local readme = vim.fn.getcwd() .. "/README.md"
  local fd = uv.fs_open(readme, "r", 438)
  if not fd then
    render.replace(buf, {"README.md 文件未找到"})
    return
  end
  local stat = uv.fs_fstat(fd)
  local data = uv.fs_read(fd, stat.size, 0)
  uv.fs_close(fd)
  if not data then
    render.replace(buf, {"README.md 读取失败"})
    return
  end
  local lines = vim.split(data, "\n")
  render.clear(buf)
  -- 分为10段，随机延迟200~4000ms串行依次渲染
  local total = #lines
  local seg = math.ceil(total/10)
  local idx = 1
  local function render_next_chunk(i)
    if i > 10 then return end
    local start_idx = (i-1)*seg+1
    local end_idx = math.min(i*seg, total)
    local chunk = {}
    for j = start_idx, end_idx do table.insert(chunk, lines[j]) end
    local delay = math.random(200, 4000)
    vim.defer_fn(function()
      render.stream_paragraph_window(buf, win, chunk, {typewriter=true, typewriter_interval=40})
      render_next_chunk(i+1)
    end, delay)
  end
  render_next_chunk(1)
end

-- Qwen流式API+渲染测试
function M.test_qwen_stream_render()
  local api = require("ai_dialog.api")
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
  local lines = {}
  api.call_qwen_api_stream(nil, {
    {role = "user", content = "帮我写一首爱情为主题的词。"}
  }, function(chunk)
    table.insert(lines, chunk)
  end)
  vim.defer_fn(function()
    render.stream_paragraph_window(buf, win, lines, {typewriter=true, parallel=true})
  end, 1200)
end

-- 并发渲染测试：逐行渲染诗词（每次只传一行）
function M.test_render_chunk_parallel()
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
  
  -- 多首诗词测试
  local poem_lines = {
    "春眠不觉晓，",
    "处处闻啼鸟。",
    "夜来风雨声，",
    "花落知多少。",
    "",
    "床前明月光，",
    "疑是地上霜。",
    "举头望明月，",
    "低头思故乡。",
    "",
    "白日依山尽，",
    "黄河入海流。",
    "欲穷千里目，",
    "更上一层楼。"
  }
  
  -- 逐行使用 render_chunk_parallel 渲染，每行间隔500毫秒
  local index = 1
  local current_line = {}
  local function render_next_line()
   
    
    table.insert(current_line, poem_lines[index])
    -- 每次只传递一行给 render_chunk_parallel
    render.render_chunk_parallel(buf, {poem_lines[index]}, {}, function()
      -- 不等待前面函数完成，直接延迟500毫秒后渲染下一行
    end)
    index = index + 1
    vim.defer_fn(render_next_line, 500)  -- 修正为500毫秒
  end
  
  -- 开始渲染第一行
  render_next_line()
end

return M
