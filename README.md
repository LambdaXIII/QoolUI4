# QoolUI4 —— 酷酷的UI

基于 Qt6/QML 的桌面 UI 组件库（第 4 代）。用它做的界面，会变得非常 Qool。

QWidgets？React？Tauri？Electron？Fluent？它们都不酷。QoolUI 想做的是那个真正酷的：以「酷酷的Box」为核心造型语言，从窗口到控件，全部基于 Qt Quick Shape 绘制，硬件加速、全矢量。

## 酷酷的Box

QoolBox 是 QoolUI 的核心形状体系，基于 QQuickShape 实现，支持八边形、圆角与矩形三种形态，四角切角独立可调。

它的性能是认真的：形状命中判定为 O(1) 的线性不等式测试，无需像素级测试；纹理与渐变填充通过 Qt 6.8 的 ShapePath::fillItem 由 GPU 完成。QoolBox 同时开放底层 ShapeHelper：可程序化定义任意多边形并快速对接到 Shape，每个控制点都可设置 Behavior 或动画。

还在 QSS 里挣扎？还在手写 paintEvent？还在为分块 update 头疼？这些都不需要了。

## 级联样式系统

QoolUI 的样式体系以 Style 附加属性贯穿所有组件：60+ 属性 × Active/Inactive/Disabled 三组状态（对应 QPalette 的 ColorGroup），沿组件树级联传播：在根节点设置一次，整个子树的控件全部生效；任何改动通过 signal 实时更新，无需手动刷新。

主题是头等公民：可设计多套主题并实时切换，No restarting required。

## 动画与性能

所有组件自带动画，默认开启，可随时全局关闭；高性能与动画两种模式随意切换。无动画状态下每个控件都有专门设计的行为，不会因性能限制展示残缺效果。动画基于 Qt 标准机制（Behavior 等），可完全自行覆盖；性能设置同样级联。

## 模块概述

### Qool
核心模块（必备）：形状体系、样式与主题、窗口等基础能力。仅此模块必备，其余模块均可按需取舍。

### Qool.Controls / Qool.Controls.Components
基于 QoolBox 的整套控件：按钮、下拉框、进度条、旋钮、滚动条等，还在扩充中。觉得成品控件集成度太高？Components 提供低集成度的基础组件：**积木**，自由拼装。

### Qool.Chat
组件间通信方案。Windows 没有 DBus？ChatRoom 提供一个所有组件共享的"聊天室"：任意组件发送的消息被 Beeper 实时接收，跨线程、线程安全，基于 Qt 事件投递，不依赖全局 Singleton；Beeper 还可安装 App 扩展能力。

### Qool.File
特化的文件处理能力：带缓存的文件信息读取与展示、完整的多选文件列表（Model 与 View 分离、不绑定样式），以及一整套酷酷的文件图标。

### 模块化与扩展
主题、文件图标等数据均可通过 QtPlugin 扩展。不喜欢自带的主题？删掉它，实现自己的。不需要的模块，整个删掉。

## 示例程序

QoolUIExample 可展示所有功能，并包含具体的行为与用法说明，推荐体验。它的代码也可以作为推荐用法的参考。

## 许可证

GPL-3.0（详见 [LICENSE](LICENSE)）。

## About Me

QoolUI 已经持续开发了很多年。一路边学边做，推倒重来过好几次，从第一代做到第四代，也攒下了不少经验。

开发它是我这些年最大的乐趣。这套东西，献给同样热爱 Qt 的大家，欢迎反馈、建议和 PR。一起学习，一起让它变得更酷。
