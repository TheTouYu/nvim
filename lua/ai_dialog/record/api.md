# API模块设计大纲（Qwen大模型对接）

## 1. 目标
- 支持通过.env文件配置API相关参数（api_key, base_url, model）
- 实现Qwen大模型API的基础调用能力
- 便于后续扩展支持更多大模型API

## 2. .env配置示例
```
url=https://dashscope.aliyuncs.com/compatible-mode/v1/chat/completions
apikey=sk-84a3367e2d814008a336749f40f462bd
model=qwen-max
```

## 3. 模块设计大纲

### 3.1 环境变量加载
- 读取.env文件，获取url、apikey、model等参数
- 提供统一的配置获取接口

### 3.2 API请求封装
- 封装Qwen大模型的chat/completions接口
- 支持传入prompt、历史对话、参数等
- 处理API返回结果，错误处理

### 3.3 对外接口
- 提供send_message(prompt, history, options)等方法
- 返回大模型回复内容

### 3.4 可扩展性
- 设计为可扩展结构，便于后续支持其他大模型API

## 4. TODO
- [ ] 读取.env配置
- [ ] 封装Qwen API请求
- [ ] 错误处理与日志
- [ ] send_message接口设计
- [ ] 支持多模型/多API扩展
- [ ] 单元测试
