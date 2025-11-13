-- lua/ai_dialog/project.lua

local M = {}

-- 存储每个项目的对话状态 { [project_root]: { buf, win, content } }
M.project_dialogs = {}

---获取当前项目根目录（使用 Neovim 内置检测）
function M.get_project_root()
  local cwd = vim.fn.getcwd()

  -- 尝试检测项目根目录（.git 目录等）
  local root_markers = { ".git", "package.json", "Cargo.toml", "pyproject.toml" }

  for _, marker in ipairs(root_markers) do
    local root = vim.fs.find(marker, { path = cwd, upward = true })[1]
    if root then
      return vim.fs.dirname(root)
    end
  end

  -- 没有找到项目标记，使用当前目录
  return cwd
end

---获取当前项目的对话状态
function M.get_current_dialog()
  local project_root = M.get_project_root()
  return M.project_dialogs[project_root]
end

-- 兼容旧用法
function M.get_crrent_dialog()
  return M.get_current_dialog()
end

---设置当前项目的对话状态
function M.set_current_dialog(dialog)
  local project_root = M.get_project_root()
  M.project_dialogs[project_root] = dialog
end

---清除当前项目的对话状态
function M.clear_current_dialog()
  local project_root = M.get_project_root()
  M.project_dialogs[project_root] = nil
end

---获取当前项目的缓存文件路径
function M.get_cache_path()
  local project_root = M.get_project_root()
  local safe_path = project_root:gsub("[/\\:]", "_")
  return vim.fn.stdpath("cache") .. "/ai_dialog/" .. safe_path .. ".log"
end

---获取当前项目的对话文件路径（保存在项目根目录）
function M.get_dialog_path()
  local project_root = M.get_project_root()
  return project_root .. "/.ai_dialog"
end

---确保缓存目录存在
function M.ensure_cache_dir()
  local cache_dir = vim.fn.stdpath("cache") .. "/ai_dialog"
  vim.fn.mkdir(cache_dir, "p")
end

function M.save_dialog(dialog)
  if not dialog then return end
  local lines = vim.api.nvim_buf_get_lines(dialog.buf, 0, -1, false)
  local cache_path = M.get_dialog_path()
  vim.fn.writefile(lines, cache_path)
end

function M.save_current_dialog()
  local dialog = M.get_current_dialog()
  if not dialog then return end
  M.save_dialog(dialog)
end

return M
