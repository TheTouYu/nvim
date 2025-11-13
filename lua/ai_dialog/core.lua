-- lua/ai_dialog/core.lua
-- 对话主流程控制模块，协调 buffer/api/render

local M = {}
local api = require("ai_dialog.api")
local render = require("ai_dialog.render")
local project = require("ai_dialog.project")
local config = require("ai_dialog.config")

-- 项目级别状态跟踪
M.project_states = {}

-- 获取当前项目的状态
local function get_project_state()
  local project_root = project.get_project_root()
  if not M.project_states[project_root] then
    M.project_states[project_root] = { generating = false }
  end
  return M.project_states[project_root]
end

-- 移动光标到指定行并进入插入模式的辅助函数
local function move_cursor_and_enter_insert_mode(win, buf)
  local line_count = vim.api.nvim_buf_line_count(buf)
  -- 确保行号有效
  if line_count >= 1 then
    vim.api.nvim_win_set_cursor(win, { line_count, 6 })
  end
  vim.cmd("startinsert!")
end

-- 安全的聊天函数：检查当前是否正在生成回复
function M.safe_chat()
  local project = require("ai_dialog.project")
  local dialog = project.get_current_dialog()
  if not dialog then
    vim.notify("请先打开对话窗口 (AIToggle)", vim.log.levels.WARN)
    return
  end
  
  -- 检查当前项目是否正在生成回复
  local project_state = get_project_state()
  if project_state.generating then
    vim.notify("正在生成回复中，请稍候...", vim.log.levels.INFO)
    return
  end
  
  -- 调用chat函数
  M.chat()
end

-- 格式化一条消息为 markdown
function M.format_message(role, content)
  if role == "system" then
    return { "💡 系统：" .. content }
  elseif role == "user" then
    return { "👤 用户: " .. content }
  elseif role == "assistant" then
    return { "🤖 AI: " .. content }
  else
    return { content }
  end
end


-- 解析 buffer 为标准消息数组和结构化渲染行
-- 优化分段解析，确保每个 user/ai/system 块都能被正确分段，不丢失内容
function M.parse_buffer_structured(buf)
  -- 检查环境变量 debug
  local debug_enabled = os.getenv("debug") == "true"
  if debug_enabled then
    print("Debug: Entering M.parse_buffer_structured")
  end
  local ok, lines = pcall(vim.api.nvim_buf_get_lines, buf, 0, -1, false)
  if not ok then
    if debug_enabled then
      print("Debug: Failed to get buffer lines: " .. tostring(lines))
    end
    return nil, "failed to get buffer lines:" .. tostring(lines)
  end
  if debug_enabled then
    print("Debug: Successfully got " .. #lines .. " lines from buffer")
  end
  local messages = {}
  local rendered = {}
  local current_role = nil
  local current_content = {}
  local has_previous_message = false

  -- 处理并添加消息块
  local function add_message_block()
    if current_role and #current_content > 0 then
      -- 清理内容中的空行
      local cleaned_content = {}
      for _, content_line in ipairs(current_content) do
        if content_line:match("%S") then -- 非空行
          table.insert(cleaned_content, content_line)
        end
      end

      if #cleaned_content > 0 then
        local content = table.concat(cleaned_content, "\n")
        table.insert(messages, { role = current_role, content = content })

        -- 在消息之间添加分割线
        if has_previous_message then
          table.insert(rendered, "---")
        end

        -- 添加消息内容
        local message_line = ""
        if current_role == "system" then
          message_line = "💡 系统：" .. content
        elseif current_role == "user" then
          message_line = "👤 用户: " .. content
        elseif current_role == "assistant" then
          message_line = "🤖 AI: " .. content
        else
          message_line = "- // "..content
        end
        
        -- 将带有换行符的内容拆分为多行
        local lines = vim.split(message_line, "\n", true)
        for _, l in ipairs(lines) do
          if l:match("%S") then -- 非空行
            table.insert(rendered, "    "..l)
          end
        end

        table.insert(rendered, "") -- 添加一个空行分隔
        has_previous_message = true
      end
    end
    current_role = nil
    current_content = {}
  end
  -- 处理未使用的内容
  local function handle_unused_content(line)
    -- 跳过空行
    if line:match("^%s*$") then
      -- 避免连续空行
      if #rendered > 0 and not rendered[#rendered]:match("^%s*$") then
        table.insert(rendered, "")
      end
      return
    end
    -- 应用替换规则
    local processed_line = line
    if config.opts.replaces then
      for pattern, replacement in pairs(config.opts.replaces) do
        processed_line = processed_line:gsub(pattern, replacement)
      end
    end
    -- 将带有换行符的内容拆分为多行
    local lines = vim.split(processed_line, "\n", true)
    for _, l in ipairs(lines) do
      if l:match("%S") then -- 非空行
        table.insert(rendered, "    "..l)
      end
    end
  end

  -- 第一遍处理：收集所有消息块
  for i = 1, #lines do
    local line = lines[i]
    line = tostring(line):gsub("^%s*(.-)%s*$", "%1") -- 去除首尾空白

    -- 跳过空行和分隔线（它们将在渲染时重新添加）
    if line:match("^%s*$") or line:match("^%-%-%-") then
      goto continue
    end

    -- 处理系统消息
    if line:match("^💡 系统：") or line:match("^system:") then
      add_message_block()
      current_role = "system"
      local content = line:gsub("^💡 系统：%s*", ""):gsub("^system:%s*", "")
      table.insert(current_content, content)
    -- 处理用户消息
    elseif line:match("^👤 用户:") or line:match("^user:") then
      add_message_block()
      current_role = "user"
      local content = line:gsub("^👤 用户:%s*", ""):gsub("^user:%s*", "")
      table.insert(current_content, content)
    -- 处理AI消息
    elseif line:match("^🤖 AI:") or line:match("^ai:") then
      add_message_block()
      current_role = "assistant"
      local content = line:gsub("^🤖 AI:%s*", ""):gsub("^ai:%s*", "")
      table.insert(current_content, content)
    -- 处理消息内容
    elseif current_role then
      table.insert(current_content, line)
    -- 处理未使用的内容
    else
      handle_unused_content(line)
    end

    ::continue::
  end

  -- 处理最后一个消息块
  add_message_block()

  -- 清理末尾的空行
  while #rendered > 0 and rendered[#rendered]:match("^%s*$") do
    table.remove(rendered, #rendered)
  end

  -- 确保内容类型正确
  for i, msg in ipairs(messages) do
    if type(msg.content) ~= "string" then
      messages[i].content = tostring(msg.content)
    end
  end

  for i, line in ipairs(rendered) do
    if type(line) ~= "string" then
      rendered[i] = tostring(line)
    end
  end

  return messages, rendered
end

-- 发送用户输入，重解析并重绘历史，渲染AI回复
function M.chat()
  local project = require("ai_dialog.project")
  local dialog = project.get_current_dialog()
  if not dialog then
    vim.notify("请先打开对话窗口 (AIToggle)", vim.log.levels.WARN)
    return
  end
  local buf = dialog.buf
  local win = dialog.win
  -- 重新解析并重绘历史
  local messages, rendered = M.parse_buffer_structured(buf)
  
  -- 检查最后一条消息是否是AI回复，如果是则自动添加分隔线和用户输入提示并进入插入模式
  local last_line = #rendered > 0 and rendered[#rendered] or ""
  if last_line:match("^🤖 AI: ") then
    -- 如果最后是AI回复，则自动添加分隔线和用户输入提示并进入插入模式
    table.insert(rendered, "---")
    table.insert(rendered, "👤 用户: ")
    
    -- 更新buffer显示
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, rendered)
    
    -- 移动光标到用户输入行并进入插入模式
    move_cursor_and_enter_insert_mode(win, buf)
    
    -- 保存对话状态
    local project = require("ai_dialog.project")
    project.save_dialog(dialog)
    return
  end
  
  -- todo 增加一行提示： ’ai 正在思考 ... ‘ 开始渲染ai的答复的时候结束
  local api = require("ai_dialog.api")
  local render = require("ai_dialog.render")
  local init_content = "🤖 AI: "
  local init_reasoning_content = "🤖 思考中: "
  
  -- 获取当前项目状态并设置生成状态
  local project_state = get_project_state()
  project_state.generating = true
  
  -- 用于存储AI回复的完整内容
  local full_ai_content = ""
  
  api.call_qwen_api_stream(nil, messages, function(chunk)
    print("chunk:", vim.inspect(chunk))
    
    if chunk.reasoning and chunk.reasoning ~= "" then 
        -- 立即渲染reasoning内容
        if init_reasoning_content ~= "" then
            chunk.reasoning = init_reasoning_content .. chunk.reasoning
            init_reasoning_content = "" -- 只在第一次添加前缀
        end
        vim.schedule(function()
          render.render_chunk_parallel(buf, {chunk.reasoning}, {typewriter=true, parallel=true})
          render.ensure_visible(win, vim.api.nvim_buf_line_count(buf))
        end)
    end
    
    if chunk.content and chunk.content ~= "" then
        if init_content ~= "" then
            chunk.content = init_content .. chunk.content
            init_content = "" -- 只在第一次添加前缀
        end

      vim.schedule(function()
        -- 使用即时渲染函数，逐个渲染新接收的内容
        render.render_chunk_parallel(buf, {chunk.content}, {typewriter=true, parallel=true})
        render.ensure_visible(win, vim.api.nvim_buf_line_count(buf))
      end)
    elseif chunk.finish_reason == 'stop' then
      vim.schedule(function()
        vim.notify("AI回复完成", vim.log.levels.INFO)

        render.render_chunk_parallel(buf, {"\n\n---","\n\n\n👤 用户:"}, {typewriter=true, parallel=true,render_force=true},function ()
            print("AI response render finished.")
            -- 调用AIReload命令重新渲染
            -- vim.cmd("AIReload")
            -- 在AI回复结束后添加分隔线和用户输入提示
            -- 移动光标到用户输入行并进入插入模式
            move_cursor_and_enter_insert_mode(win, buf)
            local project = require("ai_dialog.project")
            project.save_dialog(dialog)
            
            -- 在AI回复结束后重置生成状态
            project_state.generating = false
        end)
        
      end)
    end
  end)
end

-- 收集所有历史消息为 openai 格式
function M.collect_messages(buf)
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local messages = {}
  for _, line in ipairs(lines) do
    if line:match("^💡 系统：") or line:match("^system:") then
      local content = line:gsub("^💡 系统：%s*", ""):gsub("^system:%s*", "")
      table.insert(messages, { role = "system", content = content })
    elseif line:match("^👤 用户:") or line:match("^user:") then
      local content = line:gsub("^👤 用户:%s*", ""):gsub("^user:%s*", "")
      table.insert(messages, { role = "user", content = content })
    elseif line:match("^🤖 AI:") or line:match("^ai:") then
      local content = line:gsub("^🤖 AI:%s*", ""):gsub("^ai:%s*", "")
      table.insert(messages, { role = "assistant", content = content })
    end
  end
  return messages
end

-- 初始化对话区
function M.init_buffer(buf, project_name)
  local now = os.date("%Y-%m-%d %H:%M:%S")
  local lines = {
    "### 当前时间：" .. now,
    "### 当前项目： " .. project_name,
    "💡 系统：You are a helpful assistant.",
    "🤖 AI: Welcome to AI Dialog!",
    "👤 用户: AIRegenerate to send messages.",
    "---",
    "你可以随意编辑AI/用户的消息内容，按下 <leader>ar 重新发送。",
    "---",
    "👤 用户: ",
  }
  vim.api.nvim_buf_set_option(buf, "modifiable", true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  
  -- 初始化后自动进入插入模式
  local line_count = vim.api.nvim_buf_line_count(buf)
  vim.api.nvim_win_set_cursor(0, { line_count, 6 })
  vim.cmd("startinsert!")
end


-- 自动监听 buffer 变化，重新解析并渲染
function M.attach_autorender(buf)
  -- 添加初始化标记
  local initializing = true
  vim.api.nvim_buf_attach(buf, false, {
    on_lines = function()
      if initializing then
        initializing = false
        return true -- 跳过初始化阶段的修改
      end
      
      local project_state = get_project_state()
      print("Project generating state:", vim.inspect(project_state))
      if project_state.generating == true then
        return true
      end

      vim.schedule(function()
        if not vim.api.nvim_buf_is_valid(buf) then
          return
        end
        
        local tab, rendered = M.parse_buffer_structured(buf)
        if tab == nil then
          return
        end
        
        if vim.api.nvim_buf_is_valid(buf) then
          vim.api.nvim_buf_set_lines(buf, 0, -1, false, rendered)
        end
      end)
    end,
  })
end

-- 预留：选中内容总结/翻译/润色
function M.summarize_selection() end
function M.translate_selection() end
function M.mark_ignore() end

return M
