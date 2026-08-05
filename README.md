# QoolUI4

基于 Qt6/QML 的桌面 UI 组件库（第 4 代），以「缺角矩形」（切角矩形）为设计核心。

仅面向 Qt6（要求 Qt ≥ 6.8，开发基于最新正式版 6.11.x），不兼容 Qt5；零第三方依赖，除 Qt6 外不引入任何第三方库。

## 特性

- **缺角矩形设计体系**：八边形、圆角、矩形形状统一由 Shape API 绘制、支持纹理填充，作为窗口与控件背景的统一基础；切角参数可配置
- **统一主题**：Style 附加属性贯穿全部组件（60+ 属性 × Active/Inactive/Disabled 三组状态），内置主题数据库，支持跟随系统主题与安装自定义主题
- **成品控件族**：按钮、下拉框、进度条（含不确定态动画）、旋钮、滚动条（自动隐藏）等，全部基于 QtQuick.Templates，统一八边形造型与三态交互反馈
- **功能模块**：Qool.Chat 线程安全的频道消息系统；Qool.File 文件信息、拖放与图标体系；Qool.Debug 面向使用方应用的调试组件集
- **模块化**：仅 Qool 核心模块必备，其余模块可按需取舍
- **插件化扩展**：主题加载、文件图标等能力通过插件接口扩展（官方插件随附）

## 模块

| 模块 | 说明 |
|---|---|
| Qool | 核心模块（必备）：形状体系、主题、窗口、工具类型 |
| Qool.Controls | 控件库：成品控件 + 基础原件（原子组件） |
| Qool.Controls.Components | 基础原件层：基类、状态盖层、装饰件（随 Qool.Controls 使用） |
| Qool.Chat | 线程安全的频道消息系统 |
| Qool.File | 文件信息模型、拖放与图标体系 |
| Qool.Debug | 面向使用方应用的调试组件集 |

面向 Windows / Linux / macOS 桌面平台。更新记录见 [CHANGELOG.md](CHANGELOG.md)。

## 构建

使用 QtCreator（选择 Qt ≥ 6.8 的 kit）打开项目根目录的 `CMakeLists.txt` 即可构建并运行示例程序 QoolUIExample。运行示例时 `qoolplugins/` 目录需与可执行文件同级。

许可证：GPL-3.0（详见 [LICENSE](LICENSE)）。
