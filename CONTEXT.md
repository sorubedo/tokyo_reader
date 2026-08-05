# 东京阅读（Tokyo Reader）

一个极简的 TXT 阅读器：用户导入书籍、在书库中管理、并在阅读页阅读。应用的外观由一套 Tokyo 风格主题变体决定，用户可以在设置页选择并持久化偏好。

## Language

**主题（Theme）**:
应用的视觉外观，由当前选定的主题变体决定，并作用于整个应用。
_Avoid_: 皮肤、配色方案

**主题变体（Theme variant）**:
Tokyo 系列中一套完整、有固定名称的配色。当前共有三种：Tokyo Night、Tokyo Day、Tokyo Storm。
_Avoid_: 主题模式、主题风格

**Tokyo Night**:
默认的深色主题变体，应用启动时首次呈现的外观。
_Avoid_: 暗色模式、Night 模式

**Tokyo Day**:
浅色主题变体，对应 tokyonight.nvim 的 day 变体。
_Avoid_: 日间模式、白天主题

**Tokyo Storm**:
深蓝灰调的深色主题变体，对应 tokyonight.nvim 的 storm 变体。
_Avoid_: 风暴模式、Storm 主题

**当前主题（Current theme）**:
应用此刻正在使用的主题变体。
_Avoid_: 主题状态、激活主题

**主题选择（Theme selection）**:
用户在设置页选定、并持久化到下次启动的主题变体。默认选择为 Tokyo Night。
_Avoid_: 主题设置、用户偏好中的主题项

**设置页（Settings page）**:
管理应用偏好的页面。目前只提供主题选择，入口位于书库页。
_Avoid_: 选项页、配置页
