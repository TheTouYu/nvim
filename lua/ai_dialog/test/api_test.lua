-- test/api_test.lua
-- 测试api.lua的Qwen API调用能力

local api = require('ai_dialog.api')

local code, resp = api.test_api()
print('API返回码:', code)
print('API返回内容:', resp)

if code == 200 then
  print('Qwen API 测试通过')
else
  print('Qwen API 测试失败')
end


-- 流式API + 渲染测试（主线程安全，自动拼接内容）
print('\n--- 流式API + 渲染测试（主线程安全，自动拼接内容） ---')
local render = require('ai_dialog.render')
-- 获取编辑器窗口尺寸的80%
local editor_width = math.floor(vim.o.columns * 0.8)
local editor_height = math.floor(vim.o.lines * 0.8)
local buf = vim.api.nvim_create_buf(false, true)
local win = vim.api.nvim_open_win(buf, true, {
  relative = "editor",
  width = editor_width,
  height = editor_height,
  col = math.floor((vim.o.columns - editor_width) / 2),
  row = math.floor((vim.o.lines - editor_height) / 2),
  style = "minimal",
  border = "single",
})
local full_content = ""
api.call_qwen_api_stream(nil, {
  {role = "user", content = "请用一句话介绍你自己。"}
}, function(chunk)
  if chunk.content and chunk.content ~= "" then
    print('receive chunk:',vim.inspect(chunk))
    full_content = full_content .. chunk.content
    vim.schedule(function()
    --    render.stream_paragraph(buf, {full_content}, {typewriter=true, parallel=true})
    --   render.stream_paragraph_window(buf, win, {full_content}, {typewriter=true, parallel=true})
      render.stream_paragraph_window(buf, win, {full_content}, {typewriter=true, parallel=false})
    end)
  end
end)
