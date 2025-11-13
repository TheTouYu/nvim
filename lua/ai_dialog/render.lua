-- lua/ai_dialog/render.lua
-- 通用渲染工具模块，统一 buffer 内容操作

local M = {}
local render_worker = require("ai_dialog.render_worker")

-- 缓存每个 buffer 的下一个插入行号
M.next_line_cache = setmetatable({}, { __mode = "k" }) -- weak keys, buffer 被销毁时自动清理


local debug_enabled = os.getenv("debug") ~= nil
-- 设置指定行内容（覆盖）
function M.set_line(buf, linenr, text)
  vim.api.nvim_buf_set_lines(buf, linenr, linenr+1, false, {text})
end

-- 追加多行到 buffer 末尾
function M.append_lines(buf, lines)
  local last = vim.api.nvim_buf_line_count(buf)
  vim.api.nvim_buf_set_lines(buf, last, last, false, lines)
end

-- 在指定行插入多行
function M.insert_lines(buf, linenr, lines)
  vim.api.nvim_buf_set_lines(buf, linenr, linenr, false, lines)
end

-- 清空 buffer
function M.clear(buf)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, {})
end

-- 整体替换 buffer 内容
function M.replace(buf, lines)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
end

-- 让某一行在窗口中可见（如自动滚动）
function M.ensure_visible(win, linenr)
  local buf = vim.api.nvim_win_get_buf(win)
  local line_count = vim.api.nvim_buf_line_count(buf)
  -- 确保行号在有效范围内
  local safe_linenr = math.max(1, math.min(linenr + 1, line_count))
  vim.api.nvim_win_set_cursor(win, {safe_linenr, 0})
end

-- 动态“打字机”流动渲染：逐字渲染一段文本到指定行
function M.typewriter(buf, linenr, text, interval, cb)
  if not text then if cb then cb() end return end
  local chars = vim.split(text, "")
  local i = 1
  local timer = vim.loop.new_timer()
  local line = ""
  local closed = false
  local function safe_close()
    if not closed then
      closed = true
      timer:stop(); timer:close()
    end
  end
  timer:start(0, interval or 50, vim.schedule_wrap(function()
    if not vim.api.nvim_buf_is_valid(buf) then
      safe_close(); if cb then cb() end return
    end
    line = line .. (chars[i] or "")
    vim.api.nvim_buf_set_lines(buf, linenr, linenr+1, false, {line})
    i = i + 1
    if i > #chars then
      safe_close(); if cb then cb() end
    end
  end))
end

-- 流式渲染一个段落（多行），支持模式："append" 或 "insert"（在指定行开始追加）
-- opts.typewriter: 若为 true，则每行采用打字机效果逐字渲染
function M.stream_paragraph(buf, lines, opts)
  opts = opts or {}
  local mode = opts.mode or "append"
  local linenr = opts.linenr or 0
  local interval = opts.interval or 10
  local typewriter = opts.typewriter or true
  local idx = 1
  
  -- 展开包含换行符的行，使每个换行符都转换为独立的行
  local expanded_lines = {}
  for _, line in ipairs(lines) do
    -- 按换行符分割行，得到多个子行
    local sub_lines = vim.split(line, '\n')
    for _, sub_line in ipairs(sub_lines) do
      table.insert(expanded_lines, sub_line)
    end
  end
  
  local function render_next()
    if idx > #expanded_lines then
      if opts.on_complete then opts.on_complete() end
      return
    end
    local line = expanded_lines[idx] or ""
    if typewriter then
      local line_idx = (mode == "append") and vim.api.nvim_buf_line_count(buf) or (linenr + idx - 1)
      M.typewriter(buf, line_idx, line, opts.typewriter_interval or 50, function()
        idx = idx + 1
        render_next()
      end)
    else
      if mode == "append" then
        local last = vim.api.nvim_buf_line_count(buf)
        vim.api.nvim_buf_set_lines(buf, last, last, false, {line})
      else -- insert
        vim.api.nvim_buf_set_lines(buf, linenr + idx - 1, linenr + idx - 1, false, {line})
      end
      idx = idx + 1
      vim.defer_fn(render_next, interval)
    end
  end
  render_next()
end

-- 并发 typewriter 渲染 chunk 内多行
local function render_chunk_parallel(buf, lines, opts, on_complete)
  local run_force = opts.render_force or false

  for _,l in ipairs(lines) do
      render_worker.add_to_queue(buf, {
        line = l or "",
        opts = opts,
      })
  end

  local run_render = render_worker.check_queue_conditions(buf)
  if run_render or run_force then
    lines = render_worker.get_recent_items(buf,{render_force=run_force})
    render_worker.cleanup_all_entries(buf)
    if debug_enabled then
      print("[DEBUG] Queue conditions met, rendering queued items now. lines:", vim.inspect(lines))
    end
    
    if #lines == 0 then 
      if debug_enabled then
        print("[DEBUG] No lines to render after checking queue conditions.")
      end
      if on_complete then  on_complete() end
      return 

    end

  else
    return
  end

  -- 检查是否启用调试模式
  if debug_enabled then
    print("[DEBUG] render_chunk_parallel called with len "  .. #lines ..  " : "..vim.inspect(lines))
    print("[DEBUG] opts:", vim.inspect(opts))
  end

  -- 获取或初始化该 buffer 的下一个插入行号
  local next_line = M.next_line_cache[buf] or vim.api.nvim_buf_line_count(buf)
  local n = #lines
  M.next_line_cache[buf] = next_line+n -- 确保缓存已设置

  local finished = 0
  for i, line in ipairs(lines) do
    local line_idx = next_line + i - 1 -- 基于缓存的行号计算插入位置
    -- 每一行的延迟 = 基础延迟 * (i-1) + 随机扰动
    local base_delay = opts.base_delay or 220
    local delay = base_delay * (i-1) + math.random(0, 80)
    if n <= 2 then delay = 0 end -- 少于等于2行时不延迟
    vim.defer_fn(function()
      local type_speed = (opts.typewriter_interval or 20) + math.random(-5, 30)
      if debug_enabled then
        print("[DEBUG] Rendering line " .. i .. " with type_speed " .. type_speed)
      end
      M.typewriter(buf, line_idx, line, type_speed, function()
        finished = finished + 1
        if finished == n and on_complete then 
          if debug_enabled then
            print("[DEBUG] All lines rendered, calling on_complete,inx:",line_idx,line)
          end
          on_complete() 
        end
      end)
    end, delay)
  end
end

function M.render_chunk_parallel(buf, lines, opts, on_complete)
  render_chunk_parallel(buf, lines, opts, on_complete)
end

-- 队列管理：存储每个 buffer 的行内容队列
-- (使用 render_worker 中的实现)

-- -- 启动队列检查定时器
-- local queue_check_timer = nil
-- local function start_queue_checker()
--   if queue_check_timer then return end
  
--   -- 检查是否启用调试模式
--   if debug_enabled then
--     print("[DEBUG] Starting queue checker")
--   end
  
--   queue_check_timer = vim.loop.new_timer()
--   -- 设置定时器：每100毫秒检查一次队列
--   -- 参数说明：start(初始延迟, 重复间隔, 回调函数)
--   -- 当前设置为每100毫秒(0.1秒)执行一次
--   queue_check_timer:start(100, 1000, vim.schedule_wrap(function()
--     -- 检查所有buffer的队列
--     if debug_enabled then
--       local queues = render_worker.line_queues()
--       print("[DEBUG] Scanning for queued items, total buffers with queues: " .. vim.tbl_count(queues))
--     end
--     for buf, queue in pairs(render_worker.line_queues()) do
--       if queue.size > 0 and render_worker.check_queue_conditions(buf) then
--         if debug_enabled then
--           print("[DEBUG] Rendering queued items for buffer " .. tostring(buf) .. ", queue size: " .. queue.size)
--         end
--         render_worker.render_queued_items(buf, render_chunk_parallel)
--         render_worker.cleanup_all_entries(buf)
--       end
--     end
--   end))
-- end

-- -- 延迟启动检查器
-- vim.defer_fn(function()
--   start_queue_checker()
-- end, 100)

-- 简化版：分块流式渲染，用户滚动到未渲染区域时自动补渲染
function M.stream_paragraph_window(buf, win, lines, opts)
  opts = opts or {}
  if opts.typewriter == nil then opts.typewriter = true end
  if opts.parallel == nil then opts.parallel = true end
  local win_height = vim.api.nvim_win_get_height(win)
  local chunk_size = win_height * 3
  local total = #lines
  local rendered_to = 0
  local busy = false
  
  -- 新增：支持增量渲染的函数
  function M.render_incremental_lines(buf, new_lines, opts)
    opts = opts or {}
    local typewriter = opts.typewriter or true
    local parallel = opts.parallel or true
    local start_line = vim.api.nvim_buf_line_count(buf)
    
    if typewriter and parallel then
      -- 并行打字机渲染
      render_chunk_parallel(buf, new_lines, opts, nil)
    else
      -- 顺序渲染
      M.stream_paragraph(buf, new_lines, vim.tbl_extend("force", opts, {
        mode = "append"
      }))
    end
  end
  
  -- 新增：即时渲染函数 - 用于实时流式渲染
  function M.render_streaming_content(buf, win, content, opts)
    opts = opts or {}
    local typewriter = opts.typewriter or true
    local parallel = opts.parallel or true
    
    -- 将内容按行分割
    local lines = vim.split(content, "\n", true)
    
    -- 过滤掉空行
    local non_empty_lines = {}
    for _, line in ipairs(lines) do
      if line ~= "" then
        table.insert(non_empty_lines, line)
      end
    end
    
    if #non_empty_lines > 0 then
      -- 直接在buffer末尾追加并渲染
      if typewriter and parallel then
        render_chunk_parallel(buf, non_empty_lines, opts, nil)
      else
        M.stream_paragraph(buf, non_empty_lines, vim.tbl_extend("force", opts, {
          mode = "append"
        }))
      end
    end
  end
  
  local function render_next_chunk()
    -- print("[DEBUG] render_next_chunk called, busy=", busy, "rendered_to=", rendered_to)
    if busy then return end
    local start = rendered_to + 1
    local stop = math.min(start + chunk_size - 1, total)
    -- print("[DEBUG] chunk start=", start, "stop=", stop, "total=", total)
    if start > stop then return end
    busy = true
    local chunk_lines = vim.list_slice(lines, start, stop)
    if opts.typewriter and opts.parallel then
    --   print("[DEBUG] parallel typewriter chunk rendering...")
      render_chunk_parallel(buf, chunk_lines, opts, function()
        -- print("[DEBUG] parallel chunk finished, rendered_to=", stop)
        rendered_to = stop
        busy = false
      end)
    else
    --   print("[DEBUG] serial chunk rendering...")
      M.stream_paragraph(buf, chunk_lines, vim.tbl_extend("force", opts, {
        mode = "append",
        on_complete = function()
          print("[DEBUG] serial chunk finished, rendered_to=", stop)
          rendered_to = stop
          busy = false
        end
      }))
    end
  end
  
  -- 首次渲染
  render_next_chunk()
  
  -- 监听滚动/移动，补渲染
  vim.api.nvim_create_autocmd({"WinScrolled", "CursorMoved", "CursorMovedI"}, {
    buffer = buf,
    callback = function()
      local top = vim.fn.line('w0', win)
      local bot = vim.fn.line('w$', win)
    --   print("[DEBUG] WinScrolled: top=", top, "bot=", bot, "rendered_to=", rendered_to, "busy=", busy)
      if bot > rendered_to and not busy then
        -- print("[DEBUG] 触发补渲染: bot=", bot, "rendered_to=", rendered_to)
        render_next_chunk()
      end
    end,
    desc = "ai_dialog.render: 动态补渲染大段落"
  })
end


return M
