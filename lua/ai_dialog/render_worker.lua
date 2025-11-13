local M = {}
local uv = vim.loop

-- 检查是否启用调试模式
local debug_enabled = os.getenv("debug") ~= nil

-- 队列管理：存储每个 buffer 的行内容队列
local line_queues = {}
function M.line_queues()
  return line_queues
end
local QUEUE_TIMEOUT = 10 -- 1秒超时，毫秒单位
local MAX_QUEUE_SIZE = 3-- 最大队列大小

-- 获取 buffer 对应的队列
local function get_buffer_queue(buf)
  if not line_queues[buf] then
    if debug_enabled then
      print("[DEBUG] Creating new queue for buffer " .. tostring(buf))
    end
    line_queues[buf] = {items = {}, timestamps = {}, size = 0,full_content="",end_content=""}
  end
  return line_queues[buf]
end
function M.get_buffer_queue(buf)
  return get_buffer_queue(buf) 
end

-- 清理所有队列项
local function cleanup_all_entries(buf)
  local queue = get_buffer_queue(buf)
  if debug_enabled then
    print("[DEBUG] Cleaning up all entries for buffer " .. tostring(buf))
    print("[DEBUG] Queue size before cleanup: " .. tostring(queue.size))
  end
  queue.items = {}
  if debug_enabled then
    print("[DEBUG] Queue size after cleanup: " .. tostring(queue.size))
  end
end

function M.cleanup_all_entries(buf)
  return cleanup_all_entries(buf)
end
-- 向队列添加新行（完整参数）
local function add_to_queue(buf, item)
  
  if debug_enabled then
    print("[DEBUG] Adding to queue for buffer " .. tostring(buf) .. ": " .. vim.inspect(item))
  end

  local queue = get_buffer_queue(buf)

  local full_content = queue.full_content .. (item.line or "")
  local lines = vim.split(full_content, "\n", true)
  queue.full_content = full_content
  queue.timestamps= uv.now()
  queue.size = #lines-1
  queue.end_content = lines[#lines] or ""
  if debug_enabled then
    print("[DEBUG] full_content: " .. full_content.."lines:"..vim.inspect(lines))
    print("[DEBUG] queue:" .. vim.inspect(queue))
  end

end

function M.add_to_queue(buf,item)
  return add_to_queue(buf,item)
end

-- 获取 buffer 队列中的所有有效项（最近2秒内的）
local function get_recent_items(buf,opts)
  local queue = get_buffer_queue(buf)
  local items = vim.split(queue.full_content, "\n", true)
  local render_items = {}
  queue.rendered_size = queue.rendered_size or 0
  for i, line in ipairs(items) do
    if (opts.render_force and i>queue.rendered_size) or (i > queue.rendered_size  and i<= queue.size) then
      table.insert(render_items, line)
      queue.rendered_size = queue.rendered_size + 1
    end
  end

  if debug_enabled then
    print("[DEBUG] Getting recent items for buffer " .. tostring(buf) .. ", items: " .. vim.inspect(items),",render_items:"..vim.inspect(render_items)..",rendered_size:"..tostring(queue.rendered_size)..",size:"..tostring(queue.size))
  end
  return render_items
end
function M.get_recent_items(buf,opts)
  return get_recent_items(buf,opts)
end

-- 检查队列是否满足渲染条件
local function check_queue_conditions(buf)
  local queue = get_buffer_queue(buf)
  if queue.size == 0 then 
    if debug_enabled then
      print("[DEBUG] Queue empty for buffer " .. tostring(buf) .. ", returning false")
    end
    return false 
  end
  
  -- 满队列条件
  if queue.size >= MAX_QUEUE_SIZE then
    if debug_enabled then
      print("[DEBUG] Queue full for buffer " .. tostring(buf) .. ", returning true")
    end
    return true
  end
  
  -- 超时条件检查
  local current_time = uv.now()
    if debug_enabled then
        print("[DEBUG] Queue timeout check for buffer " .. tostring(buf))
        print("[DEBUG] Current time: " .. tostring(current_time))
        print("[DEBUG] Last update timestamp: " .. tostring(queue.timestamps))
        print("[DEBUG] Time since last update: " .. tostring(current_time - queue.timestamps))
        print("[DEBUG] Queue timeout threshold: " .. tostring(QUEUE_TIMEOUT))
    end
  if queue.size > 0 and queue.timestamps and (current_time - queue.timestamps) > QUEUE_TIMEOUT then
    return true
  end
  
  if debug_enabled then
    print("[DEBUG] Queue conditions not met for buffer " .. tostring(buf) .. ", returning false")
  end
  return false
end

-- 检查队列是否已满
local function reach_max_queued(buf)
  local queue = get_buffer_queue(buf)
  local result = queue.size >= MAX_QUEUE_SIZE
  if debug_enabled then
    print("[DEBUG] Checking if queue is full for buffer " .. tostring(buf) .. ", result: " .. tostring(result))
  end
  return result
end

function M.check_queue_conditions(buf)
  return check_queue_conditions(buf)
end

function M.reach_max_queued(buf)
  return reach_max_queued(buf)
end
-- 渲染队列中的所有项目
function M.render_queued_items(buf,render_func)
  local queue = get_buffer_queue(buf)
  local items = get_recent_items(buf)
  
  if #items == 0 then 
    if debug_enabled then
      print("[DEBUG] No items to render for buffer " .. tostring(buf))
    end
    return 
  end
  
  -- 提取所有行内容
  local lines = {}
  local opts = nil
  local all_on_complete = {}
  
  for _, item in ipairs(items) do
    table.insert(lines, item.line)
    if item.opts then
      opts = item.opts  -- 使用最后一个item的opts作为参数
    end
    if item.on_complete then
      table.insert(all_on_complete, item.on_complete)
    end
  end
  
  -- 清空队列
  if debug_enabled then
    print("[DEBUG] Rendering " .. #items .. " items for buffer " .. tostring(buf))
  end
  queue.items = {}
  queue.timestamps = {}
  queue.size = 0
  
  -- 调用原始函数进行渲染
  local original_on_complete = function()
    -- 执行所有原始的 on_complete
    for _, complete_func in ipairs(all_on_complete) do
      if complete_func then complete_func() end
    end
    if debug_enabled then
      print("[DEBUG] Completed rendering for buffer " .. tostring(buf))
    end
  end
  
  -- 递归调用原始函数进行渲染
  if #lines == 1 then
    table.insert(lines, "") -- 确保至少有2行
  end
  render_func(buf, lines, opts, original_on_complete)
end

return M
