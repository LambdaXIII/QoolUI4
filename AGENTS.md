# QoolUI4

基于 Qt6/QML 的现代化 UI 组件库（第 4 代）。

## 阅读约定

本文件是根级规范，覆盖全仓库。子模块/子目录可能带有自己的 `AGENTS.md`（模块级规范，如 `QoolUI/QoolFile/AGENTS.md`），作为本文件的补充——在该模块内工作时，必须额外阅读并遵循模块级 AGENTS。

## 仓库定位

QoolUI 是 Qt6/QML UI 组件库（基础设施），供第三方应用消费。所有公开面——QML 类型、`QoolCommon` 与 `interfaces/` 头文件 API——一律假定被第三方消费，**公开即承诺**：仓库内部没有调用方不构成省略文档、跳过稳定性考量或修改/移除 API 的依据（实例：`math::cycle_in_range` 曾因"无内部调用方"被搁置，用户指出其为多种控件的基础设施后修复）。

**暴露形式**：C++ 代码几乎全部私有、**绝不动态导出**；需要暴露的 API 一律通过 QML 引擎类型系统设计（直接注册的 C++ 类型或纯 QML 组件），不提供传统 C++ DLL 调用方式。仅有的 C++ 复用面是 `QoolCommon`（INTERFACE 头文件库）与 `interfaces/`（插件接口头）。

**私有原则**：仓库内 QML 类型默认公开、原则上不设私有；特例必须显式声明（`_private/` 目录 + `QT_QML_INTERNAL_TYPE`），源文件不得与公开 QML 混淆。注意与「暴露形式」区分：那是 C++ 暴露面的层面（几乎全私有、经 QML 暴露），本原则是仓库文件组织的层面。

**接口承诺**：`interfaces/` 插件接口为宽松承诺——接口可能演进，官方插件同步更新，第三方插件需跟随版本。

**示例程序**：QoolUIExample 兼具功能验证 prototype（持续维护，非一次性）、功能展示与宿主使用范例三重角色。

## 模块架构

**交付形态（方向）**：QoolUI 以 4 平台（msvc/mingw/darwin/linux）二进制 QML 模块包交付，每个模块是含 qmldir 的独立目录，宿主可按模块删减、仅 Qool 必备；另附带 Includes/interfaces 头文件与独立 qdoc 文档包。（具体打包方案未定，此处仅记录方向。）

```mermaid
flowchart TB
    QoolIncludes["QoolIncludes<br/>(命名空间/版本/插件接口头)"]
    QoolCommon["QoolCommon<br/>(仅头文件 C++ 模板库, 脱离 Qool 可用)"]

    subgraph Core["核心模块 (必备)"]
        Qool["Qool<br/>URI: Qool"]
    end

    subgraph L1["一级子模块 (可选, 只依赖 Qool)"]
        QoolControls["Qool.Controls<br/>组合层"]
        QoolControlsComponents["Qool.Controls.Components<br/>基础原件层"]
        QoolDebug["Qool.Debug<br/>(宿主调试工具集)"]
        QoolFile["Qool.File"]
        QoolChat["Qool.Chat"]
    end

    subgraph Plugins["外部插件 (可选, 接口契约)"]
        themeloader["themeloader"]
        fileiconprovider["fileiconprovider"]
    end

    QoolIncludes --> QoolCommon
    QoolCommon --> Qool
    Qool --> QoolControls
    Qool --> QoolControlsComponents
    Qool --> QoolDebug
    Qool --> QoolFile
    Qool --> QoolChat
    QoolControls --> QoolControlsComponents
```

### 分层

| 层 | 模块 | 定位 |
|---|---|---|
| 0 | `QoolIncludes` | 命名空间/版本头 + 插件接口（`interfaces/`），INTERFACE target |
| 1 | `QoolCommon` | 仅头文件 C++ 模板库（属性宏体系/工具/math），脱离 Qool 可用 |
| 2 | `Qool` | 核心模块：形状/样式/窗口/工具类型，QML 模块唯一必备件 |
| 3 | 一级子模块 | `Qool.Controls`、`Qool.Chat`、`Qool.File`、`Qool.Debug`——只依赖 Qool |
| 3a | 一级子模块下层 | `Qool.Controls.Components`——基础原件层，被 `Qool.Controls` 依赖（上下级关系） |
| 4 | 二级子模块（预留） | 可依赖上级模块（如 `Qool.Controls.Extra` 可依赖 `Qool.Controls`） |
| 外 | 插件 | `themeloader`/`fileiconprovider`——实现接口、独立于库本体 |

### 依赖约束

- **R1 QoolUI 内部模块间只依赖 Qool**：同级互不依赖，仅上下级可依赖。对宿主而言除 Qool 外皆可选——保证目录级删减时依赖完整（对 Qt 框架模块的依赖不受此限，如 `Qool.Debug` 额外声明 `IMPORTS QtQuick.Dialogs`）
- **R2 QoolCommon 脱离 Qool 可用**：不依赖 QtQuick，作为纯 C++ 消费面
- **R3 插件外部化**：接口用纯 Qt 类型（不引用库类型），官方插件仅是参考实现，逻辑与物理上皆可选
- **R4 基础原件在下层**：`Qool.Controls` 的控件由 `Qool.Controls.Components` 的基础原件组合而成，方向不可逆

### 依赖机制（三场景）

| 场景 | 机制 |
|---|---|
| 运行时 | QML import 语句要求模块目录存在于 import path——开发模式构建目录天然满足 |
| 交付部署 | 部署工具按 qmldir 的 import/depends 行收集依赖目录——由 CMake 的 IMPORTS/DEPENDENCIES 声明生成 |
| 编译期 AOT | qmlcachegen 需 `DEPENDENCIES TARGET` 注入 import path，缺失则类型回退运行时解析 |

**开发规范**：qmldir 由 Qt 自动生成，开发中不手写；依赖声明一律通过 `qt_add_qml_module` 的 CMake 接口配置。

## QML 模块 URI 映射

| 模块 | URI | 导入示例 |
|---|---|---|
| Qool | `Qool` | `import Qool` |
| QoolControls | `Qool.Controls` | `import Qool.Controls` |
| QoolControlsComponents | `Qool.Controls.Components` | `import Qool.Controls.Components` |
| QoolFile | `Qool.File` | `import Qool.File` |
| QoolChat | `Qool.Chat` | `import Qool.Chat` |
| QoolDebug | `Qool.Debug` | `import Qool.Debug` |

## 技术栈

| 项目 | 版本/规范 |
|---|---|
| Qt | 最新正式 Release（当前 6.11.1），绝不兼容旧版 |
| C++ | C++17+（绝不兼容旧版） |
| CMake | 3.30+ |
| 第三方依赖 | 无——绝不引入（含 Qt 5 Compatibility Module（Qt5Compat）） |
| 命名空间 | `qoolui` (宏: `QOOL_NS`) |
| 版本 | 4.0.0 |

**硬约束：零第三方依赖**。除 Qt6 外绝不引入任何第三方库/模块（含 Qt 5 Compatibility Module（Qt5Compat）等 Qt 官方兼容模块）；绝不兼容 Qt5 或旧版 C++。

**版本跟进**：只跟进 Qt 最新正式 Release，不提前迁移 prerelease/testing；一旦跟进新版，绝不 backport 旧版本功能——旧版 Qt 不可用某功能不构成适配理由（例外仅限设计 bug：问题源于本库自身缺陷时须修复，而非为旧版添加适配）。`find_package` 中的最低版本是 Qt 官方兼容性提示，不随本原则变化。

**容器与算法**：充分使用 STL 容器与算法；Qt 模块内按需选用 Qt 容器（QString/QVariant 等生态必需），但算法尽量用 STL 的——仅当算法为 Qt 容器独有或 STL 不兼容时才用 Qt 算法（Qt 官方同样推荐此做法）。

## 构建命令

```bash
# 配置 (推荐 Ninja)
cmake -B build -G Ninja -DCMAKE_BUILD_TYPE=Release

# 构建
cmake --build build

# 安装 (输出到 build/install)
cmake --install build
```

## 编码规范

### 文件命名
- C++ 头文件: `qool_类名.h` / `qool_类名.hpp`，源文件: `qool_类名.cpp`
- QML 文件: 大驼峰 `ComponentName.qml`；私有组件放 `_private/` 目录
- 附属类与主类同文件（如 `NumberMapperStop` + `NumberMapper`）

### 命名空间
所有 C++ 文件内容用宏包裹，**禁止手写 `namespace qoolui {`**：
```cpp
QOOL_NS_BEGIN
// ... 类定义
QOOL_NS_END
```
`QOOL_NS` 由 CMake 从 `includes/qoolns.hpp.config` 生成（值 = `qoolui`）。

### 属性宏体系（QoolCommon）
**禁止手写 Q_PROPERTY + getter/setter 样板**。按场景选宏族（定义见 `QoolCommon/qoolcommon/`）：

| 宏族 | 适用 | 生成内容 |
|---|---|---|
| `QOBJECT_WRITABLE/READONLY/CONSTANT_PROPERTY` | QObject 类 | 一条宏 = 信号 + getter + setter + 成员 + Q_PROPERTY |
| `QBINDABLE_*_PROPERTY(_C_, _T_, _N_)` | Qt6 bindable 属性 | 额外生成 `bindable_xxx()` |
| `QGADGET_*_PROPERTY` | Q_GADGET 值类型（无 NOTIFY） | getter + setter + 成员 + Q_PROPERTY |

- 大文件声明/定义分离：头文件用 `_DECLARE` 后缀版（仅声明），实现在 .cpp 用同宏展开
- 宏固定命名：成员 `m_xxx`、setter 参数 `new_xxx`、getter 无前缀 `xxx()`、bindable `bindable_xxx()`
- QObject 可写 setter 自动带相等守卫 + emit；宏展开到 protected 作用域（便于子类访问）
- setter 参数类型自动选择：指针传值、其余传 `const T&`
- 例外（手写 Q_PROPERTY 而非宏）：多属性共享同一信号（如 `Message::channels`/`channel` 共用 `channelsChanged`）、无成员属性、非宏体系类（如 `Theme`）
- 批量属性变更用 `Qt::beginPropertyUpdateGroup()` / `endPropertyUpdateGroup()` 包裹，使多次 emit 原子化

### 批量属性生成
同型属性清单（如 20 个 QColor）用 `QOOL_FOREACH_N` 宏 + 属性名列表批量生成（`QoolCommon/qoolcommon/macro_foreach.hpp`）：
```cpp
#define __HANDLE__(N) QOBJECT_WRITABLE_PROPERTY_DECLARE(QColor, N)
QOOL_FOREACH_10(__HANDLE__, white, silver, grey, black, ...)
#undef __HANDLE__
```
- 仅用于**同型批量属性**，单个属性直接写宏
- 可在宏族之上组合领域专属宏（如 `QOOL_DECL_POINT`/`QOOL_IMPL_POINT`：一点三属性 + bindable + 组内原子更新）
- 同一属性清单在多个类间复用保持同步（`Style` / `StyleGroupAgent` 各持一份，.cpp 用相同 FOREACH 结构生成 emit）
- 局部宏命名约定：`__HANDLE__` / `DECL` / `__SET__`，用完 `#undef`

### 方法命名分层
| 层 | 命名 | 示例 |
|---|---|---|
| QML 暴露 API（Q_INVOKABLE、属性） | camelCase | `valueAt`、`dumpInfo` |
| 内部辅助方法 | snake_case | `get_value`、`initialize_data`、`propagate_theme` |
| 槽函数 | `when_` 前缀 | `when_themeChanged` |
| QQmlListProperty 回调 / 私有辅助 | `__` 双下划线前缀 | `__appendFunction`、`__auto_insert` |

### 单例
统一用 `QoolCommon/qoolcommon/singleton.hpp` 三件套，**禁止手写静态实例**：
- 头文件: `QOOL_SIMPLE_SINGLETON_DECL(类名)`
- 源文件: `QOOL_SIMPLE_SINGLETON_QT_IMPL(类名)`（线程安全）
- 需暴露给 QML 时追加 `QOOL_SIMPLE_SINGLETON_QML_CREATE(类名)` + `QML_SINGLETON`

### 值类型（QML 可见）
内部 `struct XxxData : QSharedData` 持数据 + 门面类暴露 API：`Q_GADGET` + `QML_VALUE_TYPE(小写名)`，按可构造性选 `QML_CONSTRUCTIBLE_VALUE`（Q_INVOKABLE 构造函数）或 `QML_STRUCTURED_VALUE`。链式 API 返回 `Type&`（如 `Message::attach()`）。

### QML 逻辑对象基类
QML 列表/逻辑容器继承 `SmartObject`（`Qool/utils/qool_smartobj.h`：QQmlParserStatus + DefaultProperty(smartItems)）。需要列表属性时：`Q_CLASSINFO("DefaultProperty", ...)` + `QML_LIST_PROPERTY_ASSIGN_BEHAVIOR_REPLACE_IF_NOT_DEFAULT` + `QQmlListProperty` + `__` 静态回调。

### 调试输出
统一用 `QoolCommon/qoolcommon/debug.hpp` 宏（带类名 token 与颜色），**禁止裸 qDebug()**：
- `xDebugQ` / `xInfoQ` / `xWarningQ` / `xCriticalQ` / `xFatalQ`（带 `[类名]` token）
- 颜色 token `xDBGYellow` 等；容器输出 `xDBGVariant` / `xDBGList` / `xDBGMap` / `xDBGQPropertyList`

### 信号命名
- 属性变更: `xxxChanged`（宏生成）
- 动作/请求: 语义短语 `wannaXxx`（如 `wannaSignIn`、`wannaDumpInfo`）
- 注意 `messageRecieved` 的拼写是**既有 API，勿修正**（多处一致）

### QML 组件规范
- **多层插拔（v4 设计原则）**：控件/视图功能面按层分解——View / Delegate / Display——每层提供与相邻层配套的默认实现，但每一层都可独立替换，替换不破坏相邻层配套：
  - View 与 Model 配套（特化视图，如 `FileInfoListView` 配 `FileInfoListModel`），用户可自行实现 View
  - Delegate 与 View 配套，用户可用默认 View + 自定义 Delegate
  - Display 与 Delegate 配套（`Component` 属性暴露，如 `fileInfoDisplay`，默认 `BasicFileInfoDisplay`），用户可用默认 Delegate 沿用行为、只替换样式组件
  - 所有可显示组件最终兼容 Style 系统（`root.Style.*`）
  - 实例：Qool.File 的 FileInfoListView / FileInfoDelegate / BasicFileInfoDisplay 三层配套
- import 惯例: `import QtQuick`（无版本号）、`import QtQuick.Templates as T`、`import Qool`、`import "_private"`；必要时 `pragma ComponentBehavior: Bound`
- 根组件选择: 交互控件用 `T.*` 模板基类（T.Control / T.AbstractButton / T.ComboBox ...）；纯装饰用 Item/Text；调试叠加层用 Floater；逻辑容器用 SmartObject
- 统一 `id: root`；固定内部命名: 背景 `bgbox`、padding `spacer`（SpaceHelper）、逻辑对象 `pCtrl`、页面主列 `cc`
- 样式一律取自 `root.Style.*`（附加属性）；背景封装为 `QoolBoxSettings` 对象（属性名 `backgroundSettings`，就地覆写 `borderWidth`/`fillColor`/`cutSize*`）
- 动画用 `Basic*Behavior on X`（BasicNumber/Color/TextBehavior）+ `enabled: root.Style.animationEnabled` 门控；`animationEnabled` 控制的不只是动画，还包括一切高开销的样式效果（Shader 特效、粒子、复杂效果样式）——语义是「高性能模式 vs 完整效果」切换，而非单纯的动画开关
- 交互反馈: `ControlPressedCover` / `ControlHighlightCover` / `ControlLockedCover` 三件套
- delegate 用 `required property` 接收 model/index；对外状态用 `readonly property` 代理内部 pCtrl
- 文案一律 `qsTr()`；页面派生 `BasicPage`（required title/note），`SectionBar` 分段，`QoolTip` 内嵌
- 块尾注释标记闭合: `}//contentItem`

### QML 模块注册 (CMake)
```cmake
qt_add_qml_module(ModuleName
    URI Qool.Module      # QML 导入 URI
    VERSION ${QOOLUI_VERSION_QML}
    NAMESPACE ${QOOL_NS} # 固定为 qoolui
    IMPORTS Qool         # 声明模块依赖：写入 qmldir import 行（部署收集依据）；编译期静态解析依赖
    QML_FILES ...
    SOURCES ...
)
```
- QML 单例文件用 CMake 属性注册（而非 QML_SINGLETON 注解）: `set_source_files_properties(Xxx.qml PROPERTIES QT_QML_SINGLETON_TYPE TRUE)`——这是 .qml 文件的通道；C++ 单例的 QML 暴露走 `QML_SINGLETON` 宏（见「单例」节），两者不混用
- 文件按目录分组列出（如 `apps/xxx.h`），include 目录对应声明
- 依赖机制见「模块架构 → 依赖机制（三场景）」；qmldir 不手写

## 文档规范（QDoc）

- QDoc 注释仅从 `.cpp`/`.qdoc` 文件提取，**头文件不被 QDoc 扫描**——发布头（`qoolns.hpp`、`interfaces/*.h`）禁止 QDoc 注释，只允许普通注释（`//`、`/* */`）
- C++ QML 类型：类文档（`\qmltype` + `\nativetype`）写在对应 `.cpp`；宏生成属性无代码位置可挂 → 用独立 `\qmlproperty` 注释块，集中到 `Qool/qool.qdoc`
- `.qml` 类型：`\qmltype` 注释块紧贴 `.qml` 文件内类型上方
- 模块总览（`\qmlmodule`）与组织性文章（`\page`）必须独立 `.qdoc` 文件，放模块根目录（如 `Qool/qool.qdoc`）
- `.qdoc` 是代码的 sidecar：对应某个代码文件的 `.qdoc` 放在该文件旁边、尽量同名（如 `qool_style.cpp` → `qool_style.qdoc`）
- **QoolCommon（仅头文件库）的文档归属自身**：`\namespace`/`\fn` 等 C++ API 文档写 QoolCommon 内的独立 `.qdoc`（如 `qoolcommon/math/utils.qdoc` 承载 math 命名空间），用 `\inmodule QoolCommon` 而非 `\inqmlmodule Qool`——QoolCommon 会被第三方独立消费，文档不得挂靠 Qool 模块
- 一律不设 `doc/` 目录
- 刻意设计（非 bug 行为、设计意图）必须用 QDoc 说明，防止后续审查误判（先例：fillItem 替代 CutCornerImage、关闭按钮配件哲学、control 回退值机制）

## 变更记录

- 每次修改更新 `CHANGELOG.md`（已加入 `QOOL_GENERAL` 目标）
- 版本号不随常规修改迭代，维持 `4.0.0` 直至正式发布时递增

## 核心库瘦身原则

- 只保留通用/轻量/自洽/Qt 生态内能力；特化、有宿主归属、可被 Qt 原生替代的一律外移（V3 对比裁定先例：持久化交宿主、CutCornerImage→Qt 6.8 `ShapePath::fillItem`、图片加载→`QQuickImageProvider`）
- 本原则是「仓库定位」的推论：作为通用基础设施，特化能力不属于公开承诺范围

## 已知陷阱

### 1. QML 模块依赖声明
运行时解析靠模块目录存在于 import path（开发模式构建目录天然满足）；交付部署时部署工具按 qmldir 的 import/depends 行收集依赖目录（该行由 CMake 的 `IMPORTS`/`DEPENDENCIES` 生成）；编译期 AOT（qmlcachegen）需要 `DEPENDENCIES TARGET` 注入 import path，缺失则类型退化为运行时解析。qmldir 由 Qt 自动生成，开发中不手写，依赖声明一律通过 `qt_add_qml_module` 的 CMake 接口配置。

### 2. 插件加载路径
`qoolplugins/` 目录必须与可执行文件同级目录:
```
build/
├── QoolUIExample.exe
├── qml/
└── qoolplugins/  ← 必须在此位置
```

### 3. CMake 缓存问题
修改 QML 模块结构后需清理缓存:
```bash
rm -rf build/CMakeCache.txt build/CMakeFiles
```

### 4. 私有 QML 文件
`_private/*.qml` 需设置 `QT_QML_INTERNAL_TYPE TRUE`，不对外暴露。

## 关键文件路径

| 用途 | 路径 |
|---|---|
| 项目配置 | [qool_qml_project_setup.cmake](file:///d:/workspace/QoolUI4/qool_qml_project_setup.cmake) |
| 命名空间定义 | [includes/qoolns.hpp.config](file:///d:/workspace/QoolUI4/QoolUI/includes/qoolns.hpp.config) |
| 插件接口 | [interfaces/](file:///d:/workspace/QoolUI4/QoolUI/interfaces/) |
| 变更记录 | [CHANGELOG.md](file:///d:/workspace/QoolUI4/CHANGELOG.md) |
