# Prompt 基本规则

## 1. 日志打印规则
- 使用 Logger 类进行日志打印，避免使用 print 或 debugPrint
- Logger 方法说明：
  * `Logger.d()` - Debug级别日志，用于调试信息
  * `Logger.i()` - Info级别日志，用于常规信息
  * `Logger.w()` - Warning级别日志，用于警告信息
  * `Logger.e()` - Error级别日志，用于错误信息
- 运行命令统一使用：`flutter run | grep "AEditor"`
- Windows PowerShell 环境使用：`flutter run | Select-String "AEditor"`

## 2. 代码格式规则
- 代码块需指定语言
- 文件路径格式：```language:path/to/file
- 代码修改时只显示修改部分，使用 `// ... existing code ...` 表示未修改的代码

## 3. 目录结构规范
lib/
  ├── home/           # 首页相关
  ├── utils/          # 工具类
  │   └── logger.dart # 日志工具
  ├── models/         # 数据模型
  └── main.dart       # 入口文件

## 4. 其他规则
- 使用 markdown 格式响应
- 如果用户使用其他语言提问，使用相同语言回答
- 不要编造或猜测信息