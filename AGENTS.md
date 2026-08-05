# Repository Guidelines

## 项目结构与模块组织

这是一个基于 Flutter Web 的 TXT 阅读器，源代码按职责分层放在 `lib/` 下：

```text
lib/
  core/       # 主题与全局常量（tokyo_night.dart）
  models/     # 数据模型（book.dart）
  pages/      # 页面（library_page.dart、reader_page.dart）
  providers/  # 状态管理（library_provider.dart，基于 provider）
  services/   # 业务服务（file_import_service.dart）
test/         # 单元测试与 Widget 测试
sample_books/ # 示例 TXT 书籍
web/          # Flutter Web 入口与静态资源
```

新增源码放在 `lib/` 对应分层目录，测试放在 `test/` 下，文件名与所测模块对应。

## 构建、测试与开发命令

- `flutter pub get`：安装依赖。
- `flutter run -d web-server --web-hostname 0.0.0.0 --web-port 8000`：本地启动 Web 版（README 推荐方式）。
- `flutter analyze`：静态分析，提交前必须无告警。
- `dart format lib test`：按项目格式统一代码。
- `flutter test`：运行全部测试。

## 编码风格与命名

- 使用 2 空格缩进，并运行 `dart format` 格式化；现有代码采用单引号、尾部逗号与 `const` 构造。
- 遵循 Dart/Flutter 惯例：`snake_case` 文件名（如 `reader_page.dart`）、`PascalCase` 类名（如 `ReaderPage`）、`camelCase` 变量和方法（如 `characterCount`）。
- 使用 `flutter_lints` 推荐规则集（见 `analysis_options.yaml`），不要为了通过检查而随意添加 `// ignore`。

## 测试指南

- 框架为 `package:flutter_test`，测试文件按 `*_test.dart` 命名，如 `book_test.dart`。
- 使用 `group` 按类或功能分组，测试名描述期望行为（现有测试为中文描述，如「JSON 序列化可以完整还原」）。
- 新增逻辑或修复 bug 时补充对应测试，并运行 `flutter test` 确认通过。

## 提交与 Pull Request

- 仓库尚无提交历史，建议采用 Conventional Commits，例如 `feat: 支持导入 TXT 文件`、`fix: 修复阅读页滚动位置`、`test: 补充 Book 序列化测试`。
- PR 需说明改动目的、影响范围及验证方式；关联 issue 时在描述中引用；涉及 UI 改动附截图。保持 PR 小而聚焦，便于审查。

## 面向 Agent 的说明

本文件同样适用于 AI 代理：改动前先阅读相关源码，遵循上述命令、风格与测试要求，完成改动后运行 `flutter analyze` 和 `flutter test` 验证。
