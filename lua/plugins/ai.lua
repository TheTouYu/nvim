local prompts = {
  define = {
    command = "AIDefine",
    header_tpl = "## 定义\n\n{{input}}",
    prompt_tpl = {
      {
        role = "system",
        content = "你扮演一个字典的角色。用中文定义我提供的任何内容。输出是一个按词性分组定义的 bullet 列表，使用纯文本。每个定义项目包含使用IPA的发音、含义和最多2个使用示例。不要返回其他任何内容。",
      },
      { role = "user", content = "{{input}}" },
    },
    require_input = true,
  },
  translate = {
    command = "AITranslate",
    header_tpl = "## AI 翻译\n\n### 原文\n\n{{input}}",
    prompt_tpl = {
      {
        role = "system",
        content = "你是一名翻译。检测我提供内容的语言并将其翻译成中文。如果内容已经是中文，则将其翻译成英文。只返回翻译内容。不要返回其他任何内容。",
      },
      { role = "user", content = "{{input}}" },
    },
    require_input = true,
  },
  improve = {
    command = "AIImprove",
    header_tpl = "## AI 润色\n\n{{input}}",
    prompt_tpl = {
      {
        role = "system",
        content = "你是中文母语者。使我提供的内容更加地道，修正语法，同时保持相同的语言环境。不要返回其他任何内容。",
      },
      { role = "user", content = "{{input}}" },
    },
    require_input = true,
  },
  freeStyle = {
    command = "AIAsk",
    header_tpl = "## 问题:\n\n{{input}}",
    prompt_tpl = "{{input}}",
    require_input = true,
  },
  rock = {
    command = "AIRock",
    header_tpl = "## 讲个笑话\n\n{{input}}",
    prompt_tpl = "讲个笑话",
    require_input = false,
    models = {
      {
        model = "qwen-max",
        result_tpl = "## Qwen的笑话\n\n{{output}}",
      },
      {
        model = "deepseek",
        result_tpl = "## deepseek的笑话\n\n{{output}}",
      },
    },
  },
  -- 编程相关提示词
  explain_code = {
    command = "AIExplainCode",
    header_tpl = "## 代码解释\n\n```\n{{input}}\n```",
    prompt_tpl = {
      {
        role = "system",
        content = "你是一个编程助手。解释下面代码的功能、逻辑和可能的作用。使用中文回答。",
      },
      { role = "user", content = "解释这段代码：\n```\n{{input}}\n```" },
    },
    require_input = true,
  },
  optimize_code = {
    command = "AIOptimizeCode",
    header_tpl = "## 代码优化\n\n```\n{{input}}\n```",
    prompt_tpl = {
      {
        role = "system",
        content = "你是一个编程助手。优化下面代码，提高其可读性、性能或结构，并解释你做了哪些优化。使用中文回答。",
      },
      { role = "user", content = "优化这段代码：\n```\n{{input}}\n```" },
    },
    require_input = true,
  },
  generate_code = {
    command = "AIGenerateCode",
    header_tpl = "## 代码生成\n\n{{input}}",
    prompt_tpl = {
      {
        role = "system",
        content = "你是一个编程助手。根据用户描述生成代码片段。使用中文回答，并在代码片段前简要说明。",
      },
      { role = "user", content = "根据以下描述生成代码：\n{{input}}" },
    },
    require_input = true,
  },
  debug_code = {
    command = "AIDebugCode",
    header_tpl = "## 代码调试\n\n```\n{{input}}\n```",
    prompt_tpl = {
      {
        role = "system",
        content = "你是一个编程助手。分析下面代码可能存在的问题或错误，并提供修复建议。使用中文回答。",
      },
      { role = "user", content = "调试这段代码：\n```\n{{input}}\n```" },
    },
    require_input = true,
  },
}

return {
  "gera2ld/ai.nvim",
  dependencies = "nvim-lua/plenary.nvim",

  opts = {
    result_popup_gets_focus = false,
    prompts = prompts,
    models = {
      {
        provider = "dashscope",
        model = "qwen-flash",
        result_tpl = "## qwen-flash\n\n{{output}}",
      },
    },

    dashscope = {
      api_key = "sk-84a3367e2d814008a336749f40f462bd",
      base_url = "https://dashscope.aliyuncs.com/compatible-mode/v1",
      model = "qwen-max",
    },
    -- deepseek = {
    --   api_key = "sk-84a3367e2d814008a336749f40f462bd",
    --   base_url = "https://dashscope.aliyuncs.com/compatible-mode/v1",
    --   model = "deepseek-v3",
    -- },
  },
  config = function(_, opts)
    require("ai").setup(opts)

    -- 设置快捷键
    local keymap = vim.keymap.set

    -- 定义快捷键前缀
    -- keymap("n", "<leader>ca", "<cmd>lua require('ai').open()<CR>", { desc = "打开AI命令面板" })
    --
    -- -- 具体功能快捷键
    -- keymap({ "n", "v" }, "<leader>ad", "<cmd>AIDefine<CR>", { desc = "AI定义" })
    -- keymap({ "n", "v" }, "<leader>at", "<cmd>AITranslate<CR>", { desc = "AI翻译" })
    -- keymap({ "n", "v" }, "<leader>ai", "<cmd>AIImprove<CR>", { desc = "AI润色" })
    -- keymap({ "n", "v" }, "<leader>aa", "<cmd>AIAsk<CR>", { desc = "AI问答" })
    -- keymap({ "n", "v" }, "<leader>aj", "<cmd>AIRock<CR>", { desc = "AI讲笑话" })
    --
    -- -- 编程相关快捷键
    -- keymap({ "n", "v" }, "<leader>ae", "<cmd>AIExplainCode<CR>", { desc = "解释代码" })
    -- keymap({ "n", "v" }, "<leader>ao", "<cmd>AIOptimizeCode<CR>", { desc = "优化代码" })
    -- keymap({ "n", "v" }, "<leader>ag", "<cmd>AIGenerateCode<CR>", { desc = "生成代码" })
    -- keymap({ "n", "v" }, "<leader>ab", "<cmd>AIDebugCode<CR>", { desc = "调试代码" })
  end,
  event = "VeryLazy",
}
