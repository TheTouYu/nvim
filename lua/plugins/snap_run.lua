return {
  {

    "michaelb/sniprun",
    branch = "master",

    build = "sh install.sh",
    -- do 'sh install.sh 1' if you want to force compile locally
    -- (instead of fetching a binary from the github release). Requires Rust >= 1.65
    keys = {
      -- add a keymap to browse plugin files
      -- stylua: ignore
      -- {
      --   "<leader>ra",
      --   function() require("sniprun").run() end,
      --   desc = "run sniprun",
      -- },
      {
      "<leader>rl",
      function()
        require("sniprun.live_mode").toggle()
      end,
      desc = "toggle sniprun live mode",
       },
      {
        "<leader>ri",
        function()
          require("sniprun").info()
        end,
        desc = "sniprun info",
      },
      vim.api.nvim_set_keymap(
        "n",
        "<leader>rs",
        ":edit .log<CR>:normal! G<CR>:setfiletype json<CR>",
        { silent = true, noremap = true }
      ),
      vim.api.nvim_set_keymap(
        "n",
        "<leader>ra",
        ":!pkill -f './run.sh' ;kill $(lsof  -i :8080|awk '/LISTEN/{print $2}'); ./run.sh > .log 2>&1 & disown<CR>:edit .log<CR>:normal! G<CR>",
        { silent = false, noremap = true }
      ),
      vim.api.nvim_set_keymap(
        "n",
        "<leader>rA",
        ":!pkill -f './run.sh' ; ./run.sh > .log 2>&1 & disown<CR>:edit .log<CR>:normal! G<CR>",
        { silent = false, noremap = true }
      ),

      vim.api.nvim_set_keymap(
        "n",
        "<leader>rk",
        ":!pkill -f './run.sh' ;kill $(lsof  -i :8080|awk '/LISTEN/{print $2}'); <CR>",
        { silent = false, noremap = true }
      ),

      vim.api.nvim_set_keymap("v", "<leader>r", "<Plug>SnipRun", { silent = true }),
      vim.api.nvim_set_keymap("n", "<leader>rr", "<Plug>SnipRun", { silent = true }),
      vim.api.nvim_set_keymap("n", "<leader>rR", "<Plug>SnipReset", { silent = true }),
      vim.api.nvim_set_keymap("n", "<leader>ro", "<Plug>SnipRunOperator", { silent = true }),
      vim.api.nvim_set_keymap("n", "<leader>rw", "<Plug>SnipClose", { silent = true }),
    },

    config = function()
      require("sniprun").setup({
        display = {
          --"Classic", --# display results in the command-line  area
          -- "VirtualTextOk", --# display ok results as virtual text (multiline is shortened)

          "VirtualText", --# display results as virtual text
          -- "TempFloatingWindow",      --# display results in a floating window
          -- "LongTempFloatingWindow", --# same as above, but only long results. To use with VirtualText[Ok/Err]
          -- "Terminal", --# display results in a vertical split
          "TerminalWithCode", --# display results and code history in a vertical split
          -- "NvimNotify",              --# display with the nvim-notify plugin
          -- "Api", --# return output to a programming interface
          --
          -- "VirtualTextOk", -- 在行内显示结果
          -- "VirtualTextErr", -- 在行内显示错误信息
          -- "LongTempFloatingWindow", -- 显示长结果的临时浮动窗口
          -- "Terminal", -- 终端输出
        },
        -- 其他配置选项
        borders = "shadow", --# display borders around floating windows
        --# possible values are 'none', 'single', 'double', or 'shadow'
        -- live_display = { "VirtualTextOk" }, --# display mode used in live_mode
        live_display = { "VirtualText", "TerminalOk" }, --..or anything you want

        display_options = {
          terminal_scrollback = vim.o.scrollback, --# change terminal display scrollback lines
          terminal_line_number = false, --# whether show line number in terminal window
          terminal_signcolumn = false, --# whether show signcolumn in terminal window
          terminal_position = "vertical", --# or "horizontal", to open as horizontal split instead of vertical split
          terminal_width = 45, --# change the terminal display option width (if vertical)
          terminal_height = 20, --# change the terminal display option height (if horizontal)
          notification_timeout = 5, --# timeout for nvim_notify output
        },
        show_no_output = {
          -- "Classic",
          "TempFloatingWindow", --# implies LongTempFloatingWindow, which has no effect on its own
        },

        --# customize highlight groups (setting this overrides colorscheme)
        --# any parameters of nvim_set_hl() can be passed as-is
        snipruncolors = {
          SniprunVirtualTextOk = { bg = "#66eeff", fg = "#000000", ctermbg = "Cyan", ctermfg = "Black" },
          SniprunFloatingWinOk = { fg = "#66eeff", ctermfg = "Cyan" },
          SniprunVirtualTextErr = { bg = "#881515", fg = "#000000", ctermbg = "DarkRed", ctermfg = "Black" },
          SniprunFloatingWinErr = { fg = "#881515", ctermfg = "DarkRed", bold = true },
        },
      })
    end,
  },
}
