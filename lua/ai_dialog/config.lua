-- lua/ai_dialog/config.lua
local M = {}

-- 默认配置
M.opts = {
  -- 替换规则列表，支持正则表达式
  replaces = {
    -- { pattern = "^//", replacement = "> ↻" },
    -- { pattern = "agent专家", replacement = "你是一个agent提示词构建专家xxxx" }
  },
  
  -- API 配置
  api = {
    model = "qwen-turbo",
    base_url = "https://dashscope.aliyuncs.com/compatible-mode/v1",
    timeout = 30000
  },
  
  -- 界面配置
  ui = {
    border = "rounded",
    width = 0.8,
    height = 0.8
  },
  
  -- 自动保存配置
  auto_save = {
    enabled = true,
    interval = 5000 -- 5秒
  }
}

-- 设置配置
function M.setup(user_opts)
  user_opts = user_opts or {}
  M.opts = vim.tbl_deep_extend("force", M.opts, user_opts)
end

-- 获取替换规则
function M.get_replaces()
  return M.opts.replaces or {}
end

-- 添加替换规则
function M.add_replace(pattern, replacement)
  table.insert(M.opts.replaces, { pattern = pattern, replacement = replacement })
end

-- 清除所有替换规则
function M.clear_replaces()
  M.opts.replaces = {}
end

return M