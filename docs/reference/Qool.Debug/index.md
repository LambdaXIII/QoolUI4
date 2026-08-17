# Qool.Debug 模块

宿主调试工具集：几何指示、属性观察、形状 HUD 与交互调试件。

Qool.Debug 提供调试叠加与交互工具（依赖 QtQuick.Dialogs）：

- `ColorButton`：颜色调试按钮。
- `QoolBoxHud`：QoolBox 形状几何 HUD（读取 control 的 ext*/int* 16 点）。
- `RectResizer`：矩形交互调整器（拖动手柄调整宿主尺寸）。

> 边界暴露原则：本模块的边界条件（除零、最小尺寸、越界参数）有意暴露
> 使用问题——可见的异常行为是功能（误配置时立即发现），静默错误/崩溃
> 才算缺陷。审查时不按 bug 处理边界暴露。

## 组件参考

- [ColorButton](ColorButton.md)
- [QoolBoxHud](QoolBoxHud.md)
- [RectResizer](RectResizer.md)
