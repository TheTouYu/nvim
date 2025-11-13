-- api.lua
-- 基础API模块：读取.env环境变量并调用Qwen API

local M = {}

-- 读取.env文件
local function load_env(path)
  local env = {}
  local file = io.open(path, 'r')
  if not file then return env end
  for line in file:lines() do
    local key, value = line:match("export%s*([%w_]+)%s*=%s*(.+)")
    if key and value then
      env[key] = value
    end
  end
  file:close()
  return env
end

-- 判断debug开关
local function is_debug(env)
  return env and (env.debug == 'true' or env.debug == '1')
end

-- Qwen API请求（plenary.curl实现）
local function call_qwen_api(env, messages)
  local has_curl, curl = pcall(require, 'plenary.curl')
  if not has_curl then
    return 0, 'plenary.curl 未安装或未正确加载'
  end
  local req_body = vim.json.encode({
    model = env.model,
    messages = messages
  })
  local result = curl.post(env.url, {
    headers = {
      ["Content-Type"] = "application/json",
      ["Authorization"] = "Bearer " .. env.apikey,
    },
    body = req_body,
    timeout = 10000,
  })
  if not result or not result.status then
    return 0, 'plenary.curl 请求失败'
  end
  return result.status, result.body or ''
end

-- Qwen API流式请求（plenary.curl实现，OpenAI兼容格式，支持stream_options）
local function call_qwen_api_stream(env, messages, on_chunk)
  if not env then
    env = load_env('.env')
  end
  local debug = is_debug(env)
  local has_curl, curl = pcall(require, 'plenary.curl')
  if not has_curl then
    if debug then print('[QwenStream][Error] plenary.curl 未安装或未正确加载') end
    return false, 'plenary.curl 未安装或未正确加载'
  end
  local req_body = vim.json.encode({
    model = env.model,
    messages = messages,
    stream = true,
    stream_options = { include_usage = true }
  })
  if debug then
    print('[QwenStream][Request] url:', env.url)
    print('[QwenStream][Request] body:', req_body)
  end
  local function handle_chunk(chunk)
    if not chunk or chunk == "" then return end
    for line in chunk:gmatch("[^\r\n]+") do
      local data = line:match("^data:%s*(.*)")
      if debug then print('[QwenStream][Chunk] parsed data:', data) end
      if data == "[DONE]" then
        if debug then print('[QwenStream][Chunk] [DONE] received, stream end.') end
        return
      end
      if data and #data > 0 and on_chunk then
        local ok, obj = pcall(vim.json.decode, data)
        if ok and obj then
          if obj.choices and obj.choices[1] and obj.choices[1].delta then
            local content = obj.choices[1].delta.content or ""
            if debug then print('[QwenStream][Chunk] content:', content) end
            on_chunk({content = content,finish_reason = obj.choices[1].finish_reason,reasoning = obj.choices[1].reasoning})
          elseif obj.usage then
            if debug then print('[QwenStream][Chunk] usage:', vim.inspect(obj.usage)) end
            on_chunk({usage = obj.usage})
          end
        else
          if debug then print('[QwenStream][Chunk] 非法JSON:', data) end
        end
      end
    end
  end
  curl.post(env.url, {
    headers = {
      ["Content-Type"] = "application/json",
      ["Authorization"] = "Bearer " .. env.apikey,
    },
    body = req_body,
    timeout = 60000,
    stream = function(_, chunk)
      if debug then print('[QwenStream][Chunk] raw chunk:', chunk) end
      if chunk and #chunk > 0 then
        handle_chunk(chunk)
      end
    end,
  })
  return true, nil
end

M.call_qwen_api_stream = call_qwen_api_stream

-- 对外接口：测试API
function M.test_api()
  local env = load_env(".env")
  if not env.url or not env.apikey or not env.model then
    return false, "缺少必要的环境变量"
  end
  local messages = {
    {role = "user", content = "你好，Qwen！"}
  }
  local code, resp = call_qwen_api(env, messages)
  return code, resp
end

return M
