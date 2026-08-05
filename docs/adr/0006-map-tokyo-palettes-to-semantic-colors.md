# Tokyo 调色板通过语义颜色驱动组件

每个 Tokyo 主题变体先映射为 accent、destructive、success、warning、window、view、headerBar、border 等稳定的 Adwaita 语义颜色，页面与组件不直接引用 blue、red、comment 等原始调色板颜色。这样可以在保留 Tokyo 配色身份的同时，让组件层级和交互状态在所有主题变体中保持一致；当原始色值无法提供足够的文字、焦点或状态对比度时，允许在语义映射中调整实际使用的颜色。
