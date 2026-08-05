# 主题切换采用单主题驱动，而非 theme/darkTheme 双机制

应用需要三种主题变体（Tokyo Night、Tokyo Day、Tokyo Storm），其中 Night 与 Storm 均为深色；Flutter 的 `theme` / `darkTheme` + `themeMode` 双机制只能区分亮暗，无法表达三选一的选择，因此决定由 `ThemeProvider` 持有当前主题变体，`MaterialApp` 仅按该变体构建单一 `theme`。本设计同时意味着暂不提供「跟随系统」选项；若未来引入，需扩展主题状态机而不是改回双机制。
