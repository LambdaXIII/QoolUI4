# CONTEXT — QoolUI4

术语为稳定命名，跨会话、跨文档一律使用全称。决策记录见 `docs/adr/`；实现规范见根 `AGENTS.md`。

## 术语表

| 术语 | 定义 |
|---|---|
| **全局单例（DB）** | 进程级 C++ 单例（`QOOL_SIMPLE_SINGLETON_*` 三件套），承载 C++ 世界的能力（数据/算法/写接口），供 C++ 消费者使用。**不暴露 QML**。命名统一 **XxxDB**（Database → DB，文件名同步）。 |
| **QML 单例** | QML 类型系统中的单例概念：`QML_SINGLETON` 类型或 `pragma Singleton` QML 文件——**engine 级**概念（每 engine 至多一个实例）。 |
| **违规模式** | "C++ 进程单例 + QML_SINGLETON 暴露"：同一 QObject 跨 engine 共享，违反 Qt 契约（"There can only be one engine accessing the singleton"），会崩溃（ThemeDB SEGFAULT 0xc0000005）。 |
| **QML 侧配套对象（HQ）** | 全局单例的**消费者**：把 C++ 能力组织成 QML 可见形态（属性/方法/信号/模型）。**一定存在**（否则该能力对 QML 完全不可见）；形态自由（C++ 类 or QML 文件、单例 or 非单例）。统一命名 **XxxHQ**（类名 = QML 注册名），QML 单例每 engine 实例，**转发全部原暴露接口**（Q_INVOKABLE 方法为主，含 static/属性/信号），实现调 DB。 |
| **消费者—提供者关系** | 配套对象与全局单例之间不是转发壳（壳调用核），是消费者按自身需要组织接口；全局单例提供服务，配套对象转译成 QML 形态。 |
| **QML 文件单例** | `pragma Singleton` + CMake `QT_QML_SINGLETON_TYPE` 注册的 .qml 文件。每 engine 独立实例化，**天然安全**（不涉及跨 engine 共享）。实例：Qore / PixelFont / GlobalChatRoom。 |
| **C++-only 单例** | 进程级 C++ 单例但**不暴露 QML**（无 QML_SINGLETON/QML_ELEMENT），无契约问题。实例：SystemTheme / ChatRoomManager。 |
| **ThemeHQ** | QML 单例（每 engine 实例，`create()` → parent=engine，类名 = QML 注册名）：转发完整 QML 面——theme/anyValue/themes/count/installTheme/themeInstalled（重发）/recommendForeground/visualBrightness（static），实现调 ThemeDB。 |
| **ThemeHQModel** | 普通类型（`QML_ELEMENT`，**非单例**）：所有主题的总览列表模型；继承 `QIdentityProxyModel`（Qt 原生透传代理），构造时 `setSourceModel(ThemeDB::instance())` C++ 侧挂接；全套模型变更通知由 QAbstractProxyModel 原生转发；DB 经 C++ 指针引用（不进 QV4 值系统）。roles 与源模型一致（name/theme/metadata/constants/active/inactive/disabled/custom）。 |
| **ColorNameHQ** | QML 单例（每 engine 实例，类名 = QML 注册名）：转发查询面——names/color/categories/hasColor/name，实现调 ColorNameDB。 |
| **FileIconHQ** | QML 单例（每 engine 实例）：转发 iconUrl（Q_INVOKABLE 面）；requestPath/requrestUrl 纯 C++ 面不转发。iconUrl 实现直接调 `FileIconImageProvider::compileUrl` 静态（不经 DB）。 |
| **FileInfoHQ** | QML 单例（每 engine 实例）：转发 getFileInfo ×2，实现调 FileInfoDB（命中共享缓存）。 |
| **焦点高亮（focus highlight）** | 控件获得键盘焦点时（`visualFocus`——仅 Tab/Backtab/Shortcut 等键盘聚焦原因触发）其背景外边框临时切换至高亮色、失焦恢复的行为；为键盘操作提供可访问性可视提示。外观变化仅发生于默认 `background` 实现内，宿主替换背景后随默认实现消失。 |

## 违规集（已全部改造）

| 类（DB） | QML 面（HQ） | 模块 | App 级状态 | C++ `instance()` 消费者 |
|---|---|---|---|---|
| ThemeDB（原 ThemeDatabase） | ThemeHQ | Qool | 主题数据 + 插件（可变：installTheme） | **Style**（theme 查询） |
| ColorNameDB（原 ColorNameDatabase） | ColorNameHQ | Qool.Color | provider 表 + nameCache（init 后不可变） | 无 |
| FileIconDB | FileIconHQ | Qool.File | provider 表（init 后不可变） | **FileIconImageProvider**（requestPath） |
| FileInfoDB | FileInfoHQ | Qool.File | QCache + provider 表（缓存可变） | **FileInfo 值类型** |

## 已通过（无需改造）

- Qore / PixelFont / GlobalChatRoom —— QML 文件单例，per-engine 天然安全
- SystemTheme / ChatRoomManager —— C++-only，不暴露 QML

## 形状体系（QoolBox）

决策记录见 `docs/adr/QoolUI/0001-qml-singleton-contract.md`、`docs/adr/QoolUI/Qool/0002-qoolbox-space-layout.md`、`docs/adr/QoolUI/Qool/0003-qoolbox-single-shape.md`、`docs/adr/QoolUI/Qool/0004-qoolboxshapecontrol-rewrite.md`、`docs/adr/QoolUI/Qool/0005-qoolboxsettings-qml-cut-naming.md`、`docs/adr/QoolUI/Qool/0006-qoolboxgadget-internals.md`、`docs/adr/QoolUI/Qool/0007-qoolbox-role-split-public-surface.md`、`docs/adr/QoolUI/Qool/0008-qoolboxhud-whitebox.md`。

| 术语 | 定义 |
|---|---|
| **cut（切角）** | 八边形四角切角尺寸，规范命名 `cutSizeTL/TR/BL/BR`（四角独立）；无 singular `cutSize` 别名、无 uniform `cutSizes`。cut 是硬参数：形状由 cut 决定，尺寸不足时图形溢出而非压缩 cut。 |
| **used（usedWidth/usedHeight）** | 八边形实际承载尺寸 = max(期望尺寸, 对角 cut 和)，构造性保证边长度非负。 |
| **shrink（内缩）** | 边平移语义的内缩：内多边形 = 8 条平移半平面交集，`borderWidth` 参数化（0 = 外轮廓）。 |
| **`*Space`** | topSpace/bottomSpace/leftSpace/rightSpace，内容内缩布局量（宿主排版 padding 用），QoolBoxShapeControl（C++）计算：`max(0, max(相邻 cut) − (used − 期望)/2)`，QoolBox 转发公开；同系组件（QoolBGBox 等）覆盖同名属性是期望行为（同系同类语义）。 |
| **referenceBox** | gadget 几何委托源（5 介入点 ref 优先 null 回退）；双实例描边的内环 gadget 用它引用外环。 |
| **QoolBoxGadget** | 八边形控制点计算器（gadget 模式，挂标准 ShapeControl 之下），纯坐标数学：cut*/borderWidth → 8 点 + contains，不碰样式与 settings。由 QoolBoxShapeControl（C++）构造时安装（outer + inner 双实例，referenceBox 链）；保留公开注册，可独立使用。 |
| **settings（QoolBoxSettings）** | 外观束（几何 cut/offset/curved + 样式 border/fill/width）。单一类型（QML_ELEMENT 可实例化，ADR-0005 修订——QML 继承 Base 主路径实证否定后 Base 删除）；类型默认值 = C++ 常量，Style 默认由消费方在实例化处显式绑定。Style 供默认、settings 供实例覆盖；QObject 引用语义（整组赋值共享实例，文档契约明示）。 |
| **退行** | QoolBox 在 curved 且 cut 满足判定时退行到原生 Rectangle（非 Shape）。 |
| **gadget 模式** | 坐标计算器挂标准 ShapeControl 之下：gadget = 纯坐标数学，ShapeControl = 几何基座（target → width/height/center 等派生量）。Crystal/Circle/Triangle/QoolBox 等 gadget 共用。 |
| **双实例描边** | border 环 = 外环 gadget（borderWidth 0）+ 内环 gadget（borderWidth = 描边宽度，referenceBox 指外环）挖空；填充 = 内环单独。单 Shape 内两个 ShapePath 分别消费。 |
| **QoolBoxHud** | QoolBox 专用调试工具（OctagonShapeHud 重定位）：`box` 属性，读 `box.control` 的 ext*/int* 16 控制点（control 是 QoolBox 公开属性，无白盒契约）。 |
| **内弧半径** | 圆角变体内弧半径 = 内环相邻点弦长/√2（|intRT − intTR|/√2 等四角，Shape 自身从 control 的内环点推出；control 不加派生属性；退化弦长 0 → 半径 0）。 |
| **低级 API 组件** | OctagonShape/OctagonCurvedShape 的定位：`required` 整个 control（QoolBoxShapeControl）注入、纯消费（点/space/settings）、不持有几何——独立使用不自洽是刻意的（低级组成件，供 QoolBox 组装）。 |
| **QoolBoxShapeControl** | 八边形几何单元（ShapeControl 子类，C++）：内部安装两个 QoolBoxGadget，转发 ext*/int* 16 点、usedWidth/usedHeight、四个 *Space、contains，公开 settings（QoolBoxSettings*）——可替换/共享（QoolBox 公开 control 属性）。 |

## 属性代理（PropertyProxy）

| 术语 | 定义 |
|---|---|
| **无状态代理** | PropertyProxy 的 value 是 target.property 的透明窗口：getter 现读、setter 直写（可写时），无内部存储，数据源唯一。QML 绑定无法用字符串指定属性名，故用 C++ 无状态代理桥接任意对象属性（读 + 可选写）。 |
| **判变快照** | 轮询功能私有缓存（上次采样值），仅用于比较"值是否变化"以决定是否发 valueChanged；不参与读写行为（value 无状态，不经过它）。 |
 | **净化可写性** | isWritable 属性 = 元对象可写（`QMetaProperty::isWritable`）且非常量（`!isConstant`）——写方向守卫的单一条件；isConstant 仍独立透传。 |

## 高定组件（Color 模块）

| 术语 | 定义 |
|---|---|
| **高定组件** | 通道/取色类组件的设计定位（实例：ColorChannelSlider、HSVWheel、ColorChannelVerticalSlider）：通道视觉（渐变/光标/描边）完全**内化**为组件语义（不暴露变体式外观接口如 fillGradient/strokeColor）；插拔口=全部由模板级 delegate 或整体替换承接（`background`/`handle`，表面场景=件内 _private 视觉件）；交互契约裁剪（无 defaultValue/reset/双击重置）；通用单组件（非 per-channel 变体文件）。边界：**高定 ≠ 不可插拔**——关闭的是"变体式外观参数"，delegate 级整体替换仍开放。 |
