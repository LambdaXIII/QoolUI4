# CONTEXT — 单例组件设计模式（QoolUI4）

术语为稳定命名，跨会话、跨文档一律使用全称。决策记录见 `docs/adr/0001-qml-singleton-contract.md`；实现规范见根 `AGENTS.md`「单例」节。

## 术语表

| 术语 | 定义 |
|---|---|
| **全局单例（DB）** | 进程级 C++ 单例（`QOOL_SIMPLE_SINGLETON_*` 三件套），承载 C++ 世界的能力（数据/算法/写接口），供 C++ 消费者使用。**不暴露 QML**。命名统一 **XxxDB**（Database → DB，文件名同步）。 |
| **QML 单例** | QML 类型系统中的单例概念：`QML_SINGLETON` 类型或 `pragma Singleton` QML 文件——**engine 级**概念（每 engine 至多一个实例）。 |
| **违规模式** | "C++ 进程单例 + QML_SINGLETON 暴露"：同一 QObject 跨 engine 共享，违反 Qt 契约（"There can only be one engine accessing the singleton"），实测崩溃（ThemeDB SEGFAULT 0xc0000005）。 |
| **QML 侧配套对象（HQ）** | 全局单例的**消费者**：把 C++ 能力组织成 QML 可见形态（属性/方法/信号/模型）。**一定存在**（否则该能力对 QML 完全不可见）；形态自由（C++ 类 or QML 文件、单例 or 非单例）。统一命名 **XxxHQ**（类名 = QML 注册名），QML 单例每 engine 实例，**转发全部原暴露接口**（Q_INVOKABLE 方法为主，含 static/属性/信号），实现调 DB。 |
| **消费者—提供者关系** | 配套对象与全局单例之间不是转发壳（壳调用核），是消费者按自身需要组织接口；全局单例提供服务，配套对象转译成 QML 形态。 |
| **QML 文件单例** | `pragma Singleton` + CMake `QT_QML_SINGLETON_TYPE` 注册的 .qml 文件。每 engine 独立实例化，**天然安全**（不涉及跨 engine 共享）。实例：Qore / PixelFont / GlobalChatRoom。 |
| **C++-only 单例** | 进程级 C++ 单例但**不暴露 QML**（无 QML_SINGLETON/QML_ELEMENT），无契约问题。实例：SystemTheme / ChatRoomManager。 |
| **ThemeHQ** | QML 单例（每 engine 实例，`create()` → parent=engine，类名 = QML 注册名）：转发完整 QML 面——theme/anyValue/themes/count/installTheme/themeInstalled（重发）/recommendForeground/visualBrightness（static），实现调 ThemeDB。 |
| **ThemeHQModel** | 普通类型（`QML_ELEMENT`，**非单例**）：所有主题的总览列表模型；继承 `QIdentityProxyModel`（Qt 原生透传代理），构造时 `setSourceModel(ThemeDB::instance())` C++ 侧挂接；全套模型变更通知由 QAbstractProxyModel 原生转发；DB 经 C++ 指针引用（不进 QV4 值系统）。roles 与源模型一致（name/theme/metadata/constants/active/inactive/disabled/custom）。 |
| **ColorNameHQ** | QML 单例（每 engine 实例，类名 = QML 注册名）：转发查询面——names/color/categories/hasColor/name，实现调 ColorNameDB。 |
| **FileIconHQ** | QML 单例（每 engine 实例）：转发 iconUrl（Q_INVOKABLE 面）；requestPath/requrestUrl 纯 C++ 面不转发。iconUrl 实现直接调 `FileIconImageProvider::compileUrl` 静态（不经 DB）。 |
| **FileInfoHQ** | QML 单例（每 engine 实例）：转发 getFileInfo ×2，实现调 FileInfoDB（命中共享缓存）。 |

## 违规集（已全部改造，2026-08-13）

| 类（DB） | QML 面（HQ） | 模块 | App 级状态 | C++ `instance()` 消费者 |
|---|---|---|---|---|
| ThemeDB（原 ThemeDatabase） | ThemeHQ | Qool | 主题数据 + 插件（可变：installTheme） | **Style**（theme 查询） |
| ColorNameDB（原 ColorNameDatabase） | ColorNameHQ | Qool.Color | provider 表 + nameCache（init 后不可变） | 无 |
| FileIconDB | FileIconHQ | Qool.File | provider 表（init 后不可变） | **FileIconImageProvider**（requestPath） |
| FileInfoDB | FileInfoHQ | Qool.File | QCache + provider 表（缓存可变） | **FileInfo 值类型** |

## 已通过（无需改造）

- Qore / PixelFont / GlobalChatRoom —— QML 文件单例，per-engine 天然安全
- SystemTheme / ChatRoomManager —— C++-only，不暴露 QML
