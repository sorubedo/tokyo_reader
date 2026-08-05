# 东京阅读（tokyo_reader）

一个极简的 TXT 阅读器 Flutter Web 项目：书库 + 导入 TXT + 阅读页。

## 技术选型

| 用途 | 包 | 说明 |
| --- | --- | --- |
| Adwaita 风格主题 | [`adwaita_gtk`](https://pub.dev/packages/adwaita_gtk) |
| 选择 txt 文件 | [`file_selector`](https://pub.dev/packages/file_selector) |
| 书库持久化 | [`hive`](https://pub.dev/packages/hive) / [`hive_flutter`](https://pub.dev/packages/hive_flutter) |
| 状态管理 | [`provider`](https://pub.dev/packages/provider) |
| 路由 | [`go_router`](https://pub.dev/packages/go_router) |

## 运行

```bash
flutter pub get
flutter run -d web-server --web-hostname 0.0.0.0 --web-port 8000
```
