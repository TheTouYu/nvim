🤖 AI 对话插件开发文档
📌 项目状态总结

当前项目已完成 阶段 1：浮动窗口基础功能，包括：

    ✅ 可 toggle 的浮动对话窗口
    ✅ 项目目录感知（自动识别项目根）
    ✅ 对话内容保存在项目根目录的 .ai_dialog 文件中
    ✅ 窗口关闭时自动保存对话历史
    ✅ 切换项目自动加载对应对话
     

剩余工作：实现流式渲染、API 集成和高级交互功能，共 14 个可独立交付的任务。

📚 AI 对话插件完整开发文档
1️⃣ 项目概述
项目名称

AI Dialog - Neovim AI 对话插件
项目目标

创建一个无缝集成到 Neovim 工作流的 AI 对话系统，使开发者能够：

    与 AI 模型进行自然对话
    编辑历史对话内容并重新生成
    将对话历史作为项目资产保存
    支持 OpenAI 兼容 API 的各种模型服务
     

核心价值

    ✨ 对话即代码：对话历史保存在项目目录，可版本控制
    ✨ 完全可编辑：自由修改任何对话内容
    ✨ 流式体验：实时显示 AI 生成过程
    ✨ 项目隔离：每个项目有独立对话上下文
     

项目需求
 功能需求
FR-01
 
创建可 toggle 的浮动对话窗口
 
高
FR-02
 
窗口内容格式：
role: content
（system/user/ai）
 
高
FR-03
 
对话内容保存在项目根目录
.ai_dialog
文件
 
高
FR-04
 
支持编辑所有对话内容（包括历史消息）
 
高
FR-05
 
从当前用户消息重新生成 AI 响应
 
高
FR-06
 
支持 OpenAI 兼容 API 的流式请求
 
高
FR-07
 
自动识别项目根目录（.git/package.json 等）
 
中
FR-08
 
对话内容自动保存（窗口关闭/切换项目时）
 
中
FR-09
 
支持 Markdown 代码块渲染
 
低
FR-10
 
提供 API 配置验证命令
 
低

非功能需求
NFR-01
 
启动时间 < 50ms（不影响 Neovim 启动）
 
高
NFR-02
 
内存占用 < 10MB（空闲状态）
 
中
NFR-03
 
支持 Neovim 0.9+（Lua 配置）
 
高
NFR-04
 
无全局状态污染（项目隔离）
 
高
NFR-05
 
完整的单元测试覆盖核心功能
 
中
NFR-06
 
清晰的错误处理和用户提示
3️⃣ 技术栈
核心技术
Neovim
 
基础平台
 
0.9+
Lua
 
插件开发语言
 
内置
vim.loop
 
异步网络请求
 
内置
Treesitter
 
可选代码高亮
 
0.9+

可选依赖
plenary.nvim
 
可选异步工具
 
最新
nvim-treesitter
 
代码块高亮
 
最新

API 兼容
OpenAI
 
✅ 完全支持
 
base_url = "<https://api.openai.com/v1>"
Azure OpenAI
 
✅ 支持
 
base_url = "<https://YOUR_RESOURCE_NAME.openai.azure.com/openai/deployments/YOUR_DEPLOYMENT_NAME>"
Ollama
 
✅ 支持
 
base_url = "<http://localhost:11434/v1>"
DeepSeek
 
✅ 支持
 
base_url = "<https://api.deepseek.com/v1>"
Local Llama.cpp
 
✅ 支持
 
base_url = "<http://localhost:8080/v1>"

4️⃣ 架构设计
系统架构图
┌───────────────────────────────────────────────────┐
│                  Neovim Editor                  │
└───────────────┬─────────────────┬─────────────────┘
                │                 │
┌───────────────▼─────┐ ┌─────────▼─────────────┐
│   UI Layer          │ │   Configuration       │
│  - Floating window  │ │  - API configuration  │
│  - Buffer management│ │  - Project detection  │
└───────────┬─────────┘ └──────────┬────────────┘
            │                      │
            ▼                      ▼
┌───────────────────────────────────────────────────┐
│                Core Logic Layer                   │
│  - Message parsing & rendering                    │
│  - Stream handling                                │
│  - Regeneration logic                             │
└───────────────────────┬───────────────────────────┘
                        │
                        ▼
┌───────────────────────────────────────────────────┐
│                API Integration Layer              │
│  - HTTP client                                    │
│  - Request builder                                │
│  - Response parser                                │
│  - Error handling                                 │
└───────────────────────────────────────────────────┘

模块关系
main (plugin/ai-dialog.lua)
│
├── buffer.lua (UI & buffer management)
│   ├── ui.lua (window creation)
│   ├── stream.lua (streaming utils)
│   ├── parser.lua (message parsing)
│   └── renderer.lua (message formatting)
│
├── config.lua (configuration management)
│
├── provider/
│   └── openai.lua (API client)
│       ├── http.lua (HTTP client)
│       ├── request_builder.lua (request formatting)
│       └── response_parser.lua (response processing)
│
└── regenerate.lua (regeneration logic)
    └── parser.lua (depends on)

实现原理
5.1 项目隔离机制

问题：如何确保不同项目的对话互不干扰？

解决方案：

    使用 vim.fs.find() 检测项目根目录（基于 .git/package.json 等标记）
    为每个项目根目录维护独立的对话状态
    对话内容保存在 项目根目录/.ai_dialog
     

lua

5.2 流式渲染原理
-- 流式写入示例
local function stream_to_buffer(buf, line_idx)
  return function(chunk)
    vim.schedule(function()
      vim.api.nvim_buf_set_option(buf, "modifiable", true)
      -- 获取当前行内容并追加新内容
      local current = vim.api.nvim_buf_get_lines[buf, line_idx, line_idx + 1, true](1)
      vim.api.nvim_buf_set_lines(buf, line_idx, line_idx + 1, false, { current .. chunk })
      vim.api.nvim_buf_set_option(buf, "modifiable", false)
      -- 滚动到底部
      vim.api.nvim_win_set_cursor(0, { vim.api.nvim_buf_line_count(buf), 0 })
    end)
  end
end

-- 项目检测示例
local function get_project_root()
  local root_markers = { ".git", "package.json", "Cargo.toml" }
  for_, marker in ipairs(root_markers) do
    local root = vim.fs.find[marker, { upward = true }](1)
    if root then return vim.fs.dirname(root) end
  end
  return vim.fn.getcwd()
end

消息解析原理

问题：如何将 buffer 内容解析为结构化消息？

解决方案：

    按行扫描 buffer 内容
    识别 role: 前缀作为消息分隔
    重建消息对象数组

-- 消息解析示例
local function parse_lines(lines)
  local messages = {}
  local current = nil
  
  for i, line in ipairs(lines) do
    local role = line:match("^(system):%s*(.*)")
      or line:match("^(user):%s*(.*)")
      or line:match("^(ai):%s*(.*)")

    if role then
      if current then table.insert(messages, current) end
      current = {
        role = role,
        content = line:match("%S+:%s*(.*)") or "",
        start_line = i - 1
      }
    else
      if current and line:match("^%s*$") == nil then
        current.content = current.content .. "\n" .. line
      end
    end
  end
  
  if current then table.insert(messages, current) end
  return messages
end

重新生成功能原理

问题：如何从编辑后的历史消息重新生成 AI 响应？

解决方案：

    解析 buffer 获取完整对话历史
    找到光标所在的消息（通常是 user 消息）
    从该消息开始重建上下文
    清理后续 AI 响应
    重新发送请求

-- 重新生成示例
local function regenerate()
  local bufnr = vim.api.nvim_get_current_buf()
  local row,_ = unpack(vim.api.nvim_win_get_cursor(0))
  
  -- 1. 解析完整对话
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local messages = parser.parse_lines(lines)
  
  -- 2. 找到当前用户消息
  local current_msg = parser.get_message_at_cursor(bufnr, row)
  if not current_msg or current_msg.role ~= "user" then return end
  
  -- 3. 重建上下文（从第一条到当前消息）
  local context = {}
  for _, msg in ipairs(messages) do
    table.insert(context, msg)
    if msg.start_line == current_msg.start_line then break end
  end
  
  -- 4. 清理后续 AI 响应
  local next_line = current_msg.start_line + 1
  while next_line < #lines do
    local line = lines[next_line]
    if line:match("^(user:|system:|ai:)") then break end
    next_line = next_line + 1
  end
  vim.api.nvim_buf_set_lines(bufnr, current_msg.start_line + 1, next_line, false, {})
  
  -- 5. 重新发送请求
  api_client.stream(context, function(chunk)
    buffer.append_ai_response(chunk)
  end)
end

任务分解（执行清单）
📦 模块 1：流式渲染功能
✅ 任务 1.1：实现基础流式写入函数

描述：创建安全的流式写入函数，用于向 buffer 逐块添加内容
文件：lua/ai_dialog/stream.lua
验收标准：

    实现 append_to_line(bufnr, line_idx, content) 函数
    使用 vim.schedule 确保线程安全
    正确处理特殊字符和换行符
    实现测试命令 :AITestStream "Hello world" 50
    测试命令应逐字符显示内容（延迟 50ms）

-- stream.lua
local M = {}

-- 追加内容到指定行
function M.append_to_line(bufnr, line_idx, content)
  -- 实现代码
end

-- 测试流式显示
function M.test_stream(content, delay_ms)
  -- 实现代码
end

return M

测试步骤：

    执行 :AIToggle 打开对话窗口
    执行 :AITestStream "Testing stream..." 30
    验证内容逐字符显示（约 30ms/字符）
     

✅ 任务 1.2：实现消息结构解析器

描述：创建解析器，将 buffer 内容解析为结构化消息
文件：lua/ai_dialog/parser.lua
验收标准：

    实现 parse_lines(lines) 函数，返回结构化消息
    正确识别 system:/user:/ai: 前缀
    处理多行内容（包括代码块）
    返回每条消息的起始行号和完整内容
    实现 get_message_at_cursor(bufnr, cursor_row)
     

交付要求：

-- parser.lua
local M = {}

-- 解析 buffer 行为结构化消息
function M.parse_lines(lines)
  -- 返回 { {role="user", content="...", start_line=5}, ... }
end

-- 获取光标所在的完整消息
function M.get_message_at_cursor(bufnr, cursor_row)
  -- 返回消息对象或 nil
end

return M
测试用例：

system: 你是一个编程助手

user: 请写一个 Python 函数

ai: ```python
def hello():
    print("Hello")

应解析为 3 条消息，正确识别多行代码块。

---

#### ✅ 任务 1.3：实现消息渲染器

**描述**：创建渲染器，将结构化消息格式化为 buffer 可显示内容  
**文件**：`lua/ai_dialog/renderer.lua`  
**验收标准**：

- [ ] 实现 `format_message(message)` 函数
- [ ] 生成符合 `role: content` 格式的文本数组
- [ ] 为不同角色添加适当视觉区分（如颜色、缩进）
- [ ] 处理代码块的 Markdown 格式
- [ ] 实现 `preview_message(message)` 用于预览

**交付要求**：

```lua
-- renderer.lua
local M = {}

-- 将消息对象格式化为文本行
function M.format_message(message)
  -- 返回字符串数组
end

-- 预览格式化效果（不写入 buffer）
function M.preview_message(message)
  -- 返回预览字符串
end

return M
示例输出： user: 请写一个 Python 函数

ai: ```python
def hello():
    print("Hello")


---

#### ✅ 任务 1.4：实现新消息追加功能
**描述**：创建函数，将新消息安全追加到 buffer 末尾  
**文件**：扩展 `lua/ai_dialog/buffer.lua`  
**验收标准**：
- [ ] 实现 `append_message(message)` 函数
- [ ] 自动添加空行分隔
- [ ] 正确处理多行内容
- [ ] 保持滚动位置（新内容可见）
- [ ] 在 buffer 末尾添加时自动滚动到底部

**交付要求**：
```lua
-- buffer.lua（新增部分）
function M.append_message(message)
  -- 实现代码
end

function M.start_ai_response()
  -- 为 AI 响应准备新行
end
测试步骤： 

    执行 :AIToggle
    调用 require('ai_dialog.buffer').append_message({role="user", content="Test message"})
    验证消息正确添加到 buffer 末尾
     

 
✅ 任务 1.5：实现 AI 响应流式接收器 

描述：创建流式接收器，处理分块到达的 AI 响应
文件：lua/ai_dialog/stream_handler.lua
验收标准： 

    实现 create_stream_handler(bufnr) 函数
    处理 OpenAI 风格的 SSE 流
    逐词/逐句追加到当前 AI 响应
    处理数据格式错误（如无效 JSON）
    提供模拟流测试命令 :AITestStreamAPI
     


    -- stream_handler.lua
local M = {}

-- 创建流式处理函数
function M.create_stream_handler(bufnr)
  return function(chunk)
    -- 处理单个数据块
  end
end

-- 测试模拟 API 流
function M.test_api_stream()
  -- 实现代码
end

return M
  测试步骤： 

    执行 :AIToggle
    执行 :AITestStreamAPI
    验证模拟的 AI 响应逐字显示
     

 
✅ 任务 1.6：实现重新生成功能 

描述：创建函数，从当前用户消息重新请求 AI 响应
文件：lua/ai_dialog/regenerate.lua
验收标准： 

    实现 regenerate() 函数
    正确识别光标所在的用户消息
    从该消息开始重建上下文
    清理后续 AI 响应
    绑定快捷键 <C-r> 和命令 :AIRegenerate
     

交付要求：

  -- regenerate.lua
local M = {}

-- 从当前消息重新生成 AI 响应
function M.regenerate()
  -- 实现代码
end

return M


测试步骤： 

    执行 :AIToggle
    输入用户消息并获取 AI 响应
    编辑用户消息
    按 <C-r> 或执行 :AIRegenerate
    验证 AI 生成新响应
     

  模块 2：API 集成 
✅ 任务 2.1：实现配置管理器 

描述：创建配置模块，管理 API 连接参数
文件：lua/ai_dialog/config.lua
验收标准： 

    实现 load_config() 函数
    支持从 ~/.config/ai-dialog/config.json 读取
    支持环境变量覆盖

    提供默认值（Ollama 兼容）
    实现 validate_config() 验证配置
     

交付要求：

  -- config.lua
local M = {}

-- 加载配置（合并文件、环境变量和默认值）
function M.load()
  -- 返回 { api_key, base_url, model, ... }
end

-- 验证配置是否有效
function M.validate(config)
  -- 返回 is_valid, error_message
end

return M

  配置文件示例 (~/.config/ai-dialog/config.json):


  {
  "api_key": "sk-xxx",
  "base_url": "https://api.openai.com/v1",
  "model": "gpt-3.5-turbo"
}


任务 2.2：实现 HTTP 请求工具 

描述：创建基础 HTTP 工具，处理 OpenAI 兼容请求
文件：lua/ai_dialog/http.lua
验收标准： 

    实现 request(url, method, headers, body, on_data, on_error) 
    使用 vim.loop.http_request 实现
    支持流式响应处理
    处理连接超时（默认 30 秒）
    提供调试日志（可配置）



-- http.lua
local M = {}

-- 发送 HTTP 请求
function M.request(opts)
  -- opts: { url, method, headers, body, on_data, on_error, timeout }
end

return M

测试步骤： 

    执行 require('ai_dialog.http').request({ url = "https://api.github.com" })
    验证能收到响应数据
     

 
✅ 任务 2.3：实现 OpenAI 兼容请求构建器 

描述：创建函数，将对话上下文转换为 OpenAI API 格式
文件：lua/ai_dialog/request_builder.lua
验收标准： 

    实现 build_request(messages, config) 函数
    正确映射 role 为 system/user/assistant
    支持 stream=true 参数
    处理长上下文截断（可选）
    提供单元测试验证输出格式
     

交付要求： 
lua
 
 
1
2
3
4
5
6
7
8
9
-- request_builder.lua
local M = {}

-- 构建 API 请求体
function M.build_request(messages, config)
  -- 返回 { url, headers, body }
end

return M
 
 

输出示例: 
json
 
 
1
2
3
4
5
6
7
8
⌄
⌄
{
  "model": "gpt-3.5-turbo",
  "messages": [
    {"role": "system", "content": "You are a helpful assistant."},
    {"role": "user", "content": "Hello!"}
  ],
  "stream": true
}
 
 
 
✅ 任务 2.4：实现 OpenAI 兼容响应解析器 

描述：创建函数，解析 OpenAI 风格的流式响应
文件：lua/ai_dialog/response_parser.lua
验收标准： 

    实现 parse_chunk(data) 函数
    处理 data: {...} 格式
    提取 delta.content 字段
    处理完成标记 [DONE]
    处理错误响应
     

交付要求： 
lua
 
 
1
2
3
4
5
6
7
8
9
-- response_parser.lua
local M = {}

-- 解析单个数据块
function M.parse_chunk(data)
  -- 返回 { content, is_done, error }
end

return M
 
 

输入示例: 
text
 
 
1
2
3
data: {"choices":[{"delta":{"content":"Hello"}}]}

data: [DONE]
 
 
 
✅ 任务 2.5：实现主要 API 客户端 

描述：创建完整的 API 客户端，连接请求和响应
文件：lua/ai_dialog/provider/openai.lua
验收标准： 

    实现 stream(messages, on_chunk, on_done, on_error) 
    完整实现流式请求/响应流程
    处理连接中断和重试
    提供错误回调
    提供测试命令 :AITestAPI "Hello"
     

交付要求： 
lua
 
 
1
2
3
4
5
6
7
8
9
-- openai.lua
local M = {}

-- 发送流式请求到 AI API
function M.stream(messages, on_chunk, on_done, on_error)
  -- 实现代码
end

return M
 
 

测试步骤： 

    执行 :AIToggle
    执行 :AITestAPI "Hello"
    验证能收到模拟的 AI 响应
     

 
✅ 任务 2.6：实现配置验证命令 

描述：创建命令，验证 API 配置是否有效
文件：扩展 lua/ai_dialog/init.lua
验收标准： 

    实现 test_config() 函数
    发送简单测试请求
    显示成功/失败消息
    显示详细错误（如 API key 无效）
    命令 :AITestConfig
     

交付要求： 
lua
 
 
1
2
3
4
5
6
7
8
9
-- init.lua（新增部分）
function M.test_config()
  -- 实现代码
end

-- 注册命令
vim.api.nvim_create_user_command("AITestConfig", function()
  require("ai_dialog").test_config()
end, {})
 
 

测试步骤： 

    执行 :AITestConfig
    验证显示配置状态（有效/无效）
     

 
🧪 模块 3：集成测试 
✅ 任务 3.1：实现端到端测试脚本 

描述：创建测试脚本，验证完整工作流
文件：tests/e2e.lua
验收标准： 

    模拟打开窗口、输入消息、接收响应
    验证流式显示效果
    验证对话历史保存
    提供测试结果报告
    实现 run_tests() 函数
     

交付要求： 
lua
 
 
1
2
3
4
5
6
7
8
9
-- e2e.lua
local M = {}

-- 运行所有端到端测试
function M.run_tests()
  -- 返回 { passed, failed, results }
end

return M
 
 

测试场景： 

    打开/关闭窗口
    发送消息并接收响应
    编辑历史消息并重新生成
    切换项目验证对话隔离
     

 
✅ 任务 3.2：创建用户文档 

描述：编写简洁的用户文档和配置指南
文件：README.md
验收标准： 

    安装说明（LazyVim 和原生 Neovim）
    基本用法示例
    配置选项说明
    常见问题解答
    贡献指南
     

交付要求： 
markdown
 
 
1
2
3
4
5
6
7
8
9
10
11
12
13
⌄
⌄
⌄
⌄
# AI Dialog

[![Neovim](https://img.shields.io/badge/Neovim-0.9%2B-blueviolet)](https://neovim.io)

## 安装

### LazyVim
```lua
{
  "your-username/ai-dialog",
  dependencies = { "nvim-lua/plenary.nvim" },
  config = true,
}
 
 
配置 

创建 ~/.config/ai-dialog/config.json: 
json
 
 
1
2
3
4
5
⌄
{
  "api_key": "sk-xxx",
  "base_url": "https://api.openai.com/v1",
  "model": "gpt-3.5-turbo"
}
 
 
使用 

    :AIToggle - 打开/关闭对话窗口
    :AIRegenerate - 重新生成当前对话
    <C-r> - 快捷键重新生成
     

... 
 
 
1
2
3
4
5
6
7
8
9
10
11
12
13

---

## 7️⃣ 开发指南

### 环境设置

1. 确保 Neovim 0.9+ 已安装
2. 创建项目目录结构：
```bash
mkdir -p ~/.config/nvim/plugin
mkdir -p ~/.config/nvim/lua/ai_dialog
mkdir -p ~/.config/ai-dialog
 
 
开发工作流 

    编辑 Lua 文件
    重启 Neovim 或重新加载模块：
     

vim
 
 
1
2
:lua package.loaded['ai_dialog'] = nil
:lua require('ai_dialog')
 
 

    使用测试命令验证功能：
     

vim
 
 
1
2
3
:AIToggle
:AITestStream "Hello" 50
:AITestAPI "Hello"
 
 
调试技巧 

    启用调试日志：
     

lua
 
 
1
2
3
4
5
6
-- 在相关模块中添加
local function debug(...)
  if vim.g.ai_dialog_debug then
    print("[AI Dialog]", ...)
  end
end
 
 

    在 Neovim 中启用调试：
     

vim
 
 
1
:let g:ai_dialog_debug = 1
 
 

    查看错误：
     

vim
 
 
1
:messages
 
 
 
8️⃣ 项目规范 
代码风格 

    使用 2 空格缩进
    函数命名使用 snake_case
    模块导出使用 local M = {} 模式
    保持每行 < 100 字符
     

提交规范 
 
 
1
2
3
4
5
[模块]: 简洁描述

详细说明（可选）

Closes #issue-number
 
 

示例： 
 
 
1
2
3
4
5
6
7
stream: implement basic stream writing

- Add append_to_line function
- Handle special characters properly
- Implement test command :AITestStream

Closes #1
 
 
测试要求 

    每个任务必须包含验证步骤
    核心功能需要单元测试
    所有 API 集成功能需要模拟测试
     

 
📌 项目状态跟踪表 
1.1 基础流式写入
 
🟡 进行中
 
 
 
1.2 消息结构解析
 
⚪ 未开始
 
 
 
1.3 消息渲染器
 
⚪ 未开始
 
 
 
1.4 新消息追加
 
⚪ 未开始
 
 
 
1.5 AI 响应接收器
 
⚪ 未开始
 
 
 
1.6 重新生成功能
 
⚪ 未开始
 
 
 
2.1 配置管理器
 
⚪ 未开始
 
 
 
2.2 HTTP 请求工具
 
⚪ 未开始
 
 
 
2.3 请求构建器
 
⚪ 未开始
 
 
 
2.4 响应解析器
 
⚪ 未开始
 
 
 
2.5 API 客户端
 
⚪ 未开始
 
 
 
2.6 配置验证
 
⚪ 未开始
 
 
 
3.1 端到端测试
 
⚪ 未开始
 
 
 
3.2 用户文档
 
⚪ 未开始
 
 
 
 
 
 
🚀 下一步行动 

    分配任务：将 14 个任务分配给不同开发者
    设置里程碑：
        Milestone 1：流式渲染模块完成（任务 1.1-1.6）
        Milestone 2：API 集成模块完成（任务 2.1-2.6）
        Milestone 3：项目发布（任务 3.1-3.2）
         
    每日同步：确认任务状态和阻塞问题
     

 

