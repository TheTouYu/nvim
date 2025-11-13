return {
  -- Excel编辑插件
  -- 提供Excel到CSV的转换和编辑功能
  "excel-editor",
  dir = "/tmp", -- 使用本地插件目录
  keys = {
    {
      "<leader>fee",
      function()
        local current_file = vim.fn.expand("%:p")
        local file_extension = vim.fn.expand("%:e")

        -- 检查是否为Excel文件
        if file_extension ~= "xlsx" and file_extension ~= "xls" then
          vim.notify("当前文件不是Excel格式", vim.log.levels.ERROR)
          return
        end

        local venv_path = vim.fn.expand("~/app/excel_venv")
        local python_path = venv_path .. "/bin/python"
        local script_path = vim.fn.expand("~/bindolabs/iflow/scripts/excel_to_csv.py")
        local csv_file = vim.fn.fnamemodify(current_file, ":r") .. ".csv"

        -- 记录日志
        vim.notify("正在转换Excel文件: " .. current_file, vim.log.levels.INFO)
        vim.notify("使用Python路径: " .. python_path, vim.log.levels.DEBUG)
        vim.notify("使用脚本路径: " .. script_path, vim.log.levels.DEBUG)
        vim.notify("目标CSV文件: " .. csv_file, vim.log.levels.DEBUG)

        -- 检查文件是否存在
        if vim.fn.filereadable(current_file) == 0 then
          vim.notify("Excel文件不存在: " .. current_file, vim.log.levels.ERROR)
          return
        end

        -- 检查Python和脚本是否存在
        if vim.fn.executable(python_path) == 0 then
          vim.notify("Python解释器不存在: " .. python_path, vim.log.levels.ERROR)
          return
        end

        if vim.fn.filereadable(script_path) == 0 then
          vim.notify("转换脚本不存在: " .. script_path, vim.log.levels.ERROR)
          return
        end

        -- 执行转换
        local cmd = python_path .. " " .. script_path .. " " .. vim.fn.shellescape(current_file)
        vim.notify("执行命令: " .. cmd, vim.log.levels.DEBUG)

        vim.fn.jobstart(cmd, {
          on_exit = function(_, code, _)
            if code == 0 then
              -- 转换成功，打开CSV文件
              vim.notify("Excel到CSV转换成功", vim.log.levels.INFO)
              vim.cmd("edit " .. csv_file)
              vim.notify("Excel文件已转换为CSV并打开", vim.log.levels.INFO)
            else
              vim.notify("Excel到CSV转换失败，退出码: " .. code, vim.log.levels.ERROR)
            end
          end,
          on_stderr = function(_, data, _)
            if data then
              for _, line in ipairs(data) do
                if line and line ~= "" then
                  vim.notify("STDERR: " .. line, vim.log.levels.ERROR)
                end
              end
            end
          end,
          on_stdout = function(_, data, _)
            if data then
              for _, line in ipairs(data) do
                if line and line ~= "" then
                  vim.notify("STDOUT: " .. line, vim.log.levels.INFO)
                end
              end
            end
          end,
        })
      end,
      desc = "打开Excel文件为CSV进行编辑",
    },
    {
      "<leader>fec",
      function()
        local current_file = vim.fn.expand("%:p")
        local file_extension = vim.fn.expand("%:e")

        -- 检查是否为CSV文件
        if file_extension ~= "csv" then
          vim.notify("当前文件不是CSV格式", vim.log.levels.ERROR)
          return
        end

        local venv_path = vim.fn.expand("~/app/excel_venv")
        local python_path = venv_path .. "/bin/python"
        local script_path = vim.fn.expand("~/bindolabs/iflow/scripts/csv_to_excel.py")
        local excel_file = vim.fn.fnamemodify(current_file, ":r") .. ".xlsx"

        -- 记录日志
        vim.notify("正在转换CSV文件: " .. current_file, vim.log.levels.INFO)
        vim.notify("使用Python路径: " .. python_path, vim.log.levels.DEBUG)
        vim.notify("使用脚本路径: " .. script_path, vim.log.levels.DEBUG)
        vim.notify("目标Excel文件: " .. excel_file, vim.log.levels.DEBUG)

        -- 检查文件是否存在
        if vim.fn.filereadable(current_file) == 0 then
          vim.notify("CSV文件不存在: " .. current_file, vim.log.levels.ERROR)
          return
        end

        -- 检查Python和脚本是否存在
        if vim.fn.executable(python_path) == 0 then
          vim.notify("Python解释器不存在: " .. python_path, vim.log.levels.ERROR)
          return
        end

        if vim.fn.filereadable(script_path) == 0 then
          vim.notify("转换脚本不存在: " .. script_path, vim.log.levels.ERROR)
          return
        end

        -- 执行转换
        local cmd = python_path .. " " .. script_path .. " " .. vim.fn.shellescape(current_file)
        vim.notify("执行命令: " .. cmd, vim.log.levels.DEBUG)

        vim.fn.jobstart(cmd, {
          on_exit = function(_, code, _)
            if code == 0 then
              vim.notify("CSV到Excel转换成功", vim.log.levels.INFO)
              vim.notify("CSV文件已保存为Excel格式: " .. excel_file, vim.log.levels.INFO)
            else
              vim.notify("CSV到Excel转换失败，退出码: " .. code, vim.log.levels.ERROR)
            end
          end,
          on_stderr = function(_, data, _)
            if data then
              for _, line in ipairs(data) do
                if line and line ~= "" then
                  vim.notify("STDERR: " .. line, vim.log.levels.ERROR)
                end
              end
            end
          end,
          on_stdout = function(_, data, _)
            if data then
              for _, line in ipairs(data) do
                if line and line ~= "" then
                  vim.notify("STDOUT: " .. line, vim.log.levels.INFO)
                end
              end
            end
          end,
        })
      end,
      desc = "将当前CSV文件保存为Excel格式",
    },
  },
}
