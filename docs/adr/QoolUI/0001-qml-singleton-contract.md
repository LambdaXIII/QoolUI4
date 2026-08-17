# ADR-0001：QML 单例契约——全局单例摘除 QML 暴露，HQ 转发层 + HQModel

> 状态：**已实施**（2026-08-13，spec singleton-design 8 张 tickets 全部完成）
> 决策定案于设计会话；本文件为定案版（含实施验证结论）。

## 背景

ThemeDB 在 QUICK_TEST_MAIN（每 tst 文件独立 QQmlEngine）下跨 engine 崩溃（0xc0000005，栈顶 `QV4::Value::fromHeapObject`）。根因（实测证据链）：

- `ThemeDatabase` 是进程级 C++ 单例（`QOOL_SIMPLE_SINGLETON_*`），经 `QML_SINGLETON` 暴露；
- Qt 契约（qmlsingletons.qdoc）：共享实例暴露为 singleton 时只能被**一个** QQmlEngine 访问；
- 多 engine 时同一 QObject 被多个 engine 的 QV4 上下文使用 → 崩溃；
- 对照实验（每 engine 独立实例不崩）坐实根因。

排查发现该模式（进程单例 + QML_SINGLETON）在仓库共 4 处：ThemeDatabase / ColorNameDatabase / FileIconDB / FileInfoDB——系统性契约违规，非单点。

## 决策

### 共有模式

1. **全局单例摘除 QML 暴露**：C++ 侧保留进程级单例承载 C++ 能力；从 QML 类型系统摘除（QML_SINGLETON/QML_ELEMENT/QML_NAMED_ELEMENT）。
2. **QML 侧配套 = 消费者对象**：一定存在（否则能力 QML 不可见）；形态逐类定（本仓统一为三件套）。
3. **关系**：消费者—提供者（非转发壳）。
4. **QML 文件单例（pragma Singleton）与 C++-only 单例**不在违规集，不动（Qore/PixelFont/GlobalChatRoom 通过；SystemTheme/ChatRoomManager 通过）。
5. **不独立处理线程问题**（会话边界），仅保证新模式双侧功能可实现；单线程契约文档化。

### 统一拆分规则（三件套）

- **DB（原类改名 XxxDB，全局单例，C++）**：全部方法/状态/逻辑**原地保留**（含原 Q_INVOKABLE 方法）；**移除 Q_INVOKABLE 标记**（不再 QML 暴露，标记误导）；摘除 QML 注册（QML_SINGLETON/QML_ELEMENT/QML_NAMED_ELEMENT/QML_CREATE）。
- **HQ（新类 XxxHQ，QML 单例，每 engine 实例，`create()` → `new XxxHQ(engine)`，parent = engine，类名 = QML 注册名）**：转发全部原暴露接口，实现 = 调 `DB::instance()`。
- **接口双侧保留**：DB 的 C++ 面（无 Q_INVOKABLE 标记）+ HQ 的 QML 面，逻辑单份在 DB，HQ 是 QML 面载体。
- **转发规则边界**：
  1. static Q_INVOKABLE（recommendForeground/visualBrightness）：DB 保留 static（去标记），HQ 上 static 转发；
  2. 属性（themes/count）：HQ 提供同名属性（读 DB）；
  3. 信号（themeInstalled）：HQ 监听 DB 信号重发（QML 侧可 connect）；
  4. 非 Q_INVOKABLE 纯 C++ 方法（FileIconDB 的 requestPath/requrestUrl）：**不转发**——HQ 只承载 QML 面；
  5. 模型面例外：不转发——独立 HQModel；
  6. FileIconHQ 例外：iconUrl 实现直接调 `FileIconImageProvider::compileUrl` 静态（不经 DB——其实现本就等价于该静态函数，不碰 DB 状态）。

### 命名体系

- HQ 后缀，**类名 = QML 注册名**（双侧同名，无需 NAMED_ELEMENT 映射）。
- 数据供应类全部改名 **XxxDB**（Database → DB，文件名同步）：ThemeDatabase → ThemeDB（`qool_theme_database.*` → `qool_theme_db.*`）、ColorNameDatabase → ColorNameDB（`qool_colornamedatabase.*` → `qool_colorname_db.*`）；FileIconDB/FileInfoDB 文件名已符合。
- QML 消费面随改名：ThemeDB → ThemeHQ、ColorDB → ColorNameHQ、FileIconDB → FileIconHQ、FileInfoDB → FileInfoHQ。

## 各类型拆分

| 域 | DB（C++ 全局单例，不暴露 QML） | HQ（QML 单例，每 engine 实例） | 模型 |
|---|---|---|---|
| Theme | 数据 + 插件 + 查询（theme/anyValue）+ 写面（installTheme）+ 模型特性（QAbstractListModel） | theme/anyValue/themes/count/installTheme/themeInstalled（重发）/recommendForeground/visualBrightness（static） | ThemeHQModel（QIdentityProxyModel，构造时 C++ 侧挂接 DB） |
| ColorName | provider 表 + nameCache + 查询 ×5（零 C++ 消费者，接口保留） | 查询 ×5 | 无 |
| FileIcon | provider 表 + requestPath/requrestUrl（FileIconImageProvider 路由） | iconUrl（= compileUrl 静态，不经 DB） | 无 |
| FileInfo | QCache + provider 表 + getFileInfo ×2（FileInfo 值类型用，缓存逻辑单份） | getFileInfo ×2（命中共享缓存） | 无 |

- **ThemeHQModel**：普通类型（`QML_ELEMENT`，非单例），继承 `QIdentityProxyModel`，构造时 `setSourceModel(ThemeDB::instance())`；全套模型变更通知由 QAbstractProxyModel 原生转发；DB 经 C++ 指针引用（不进 QV4 值系统，规避跨 engine QObject 共享类别）。roles 与源模型一致（name/theme/metadata/constants/active/inactive/disabled/custom）。
  - 修订记录：早先"去模型化 + 自实现模型"方案被本版替代（实现量最小、无重复模型实现、Qt 标准机制）；DB 模型特性保留且被 ThemeHQModel 消费。
- **C++ 消费方零改动**（除类名跟随改名）：Style（theme 查询）→ ThemeDB、FileIconImageProvider（requestPath）→ FileIconDB、FileInfo 值类型（getFileInfo）→ FileInfoDB。
- **插件加载时机不变**：DB 的 `instance()` 首次调用时构造并安装插件（App 级只加载一次）。

## 实施落地（2026-08-13）

- 4 个 DB 改名/摘暴露完成（含文件名同步 + CMake 引用）；4 个 HQ 新建（QML 单例 create() 每 engine 实例）；ThemeHQModel 新建。
- 仓库内全部 QML 面引用迁移（ThemeDB→ThemeHQ 11 处调用 + 注释/qdoc、ColorDB→ColorNameHQ 4 组件、FileInfoDB→FileInfoHQ example 1 处）；grep 验收 `ThemeDB.`/`ColorDB.`/`FileInfoDB.` 点调用零残留。
- `QOOL_SIMPLE_SINGLETON_QML_CREATE` 宏从 singleton.hpp 删除（违规模式载体，防回归；DECL/IMPL 保留仍被 DB 类使用）。
- AGENTS.md「单例」节改写为模式固化（三选一形态 + 三件套规范 + 硬约束）；QML 模块注册节的 C++ 单例指引同步修订。
- QDoc 更新：4 个 HQ/HQModel 类型文档（生命周期"进程级 QML 单例"→ 每 engine 实例 + App 级共享数据）；qool.qdoc style-system page 补 ThemeHQ 分层；ColorNameDB 的 ColorDB QDoc 迁移至 ColorNameHQ。
- **验证**：新增 4 个测试单元（QoolUITests core）全绿——跨 engine 契约（4 HQ 参数化：engine1 加载→析构→engine2 重建不崩+值一致）、QML 写面+信号转发、ThemeHQModel（模型契约+rowsInserted 转发+双实例一致）、DB 接口保留+HQ 转发等价；ctest 14/14（9 既有 + 4 新 + QML 批次 tst_qool_qml 多 engine 生态回归）通过。

## 后果

- 正面：契约合规；接口双侧保留（C++ 面 + QML 面）；数据 App 级共享恢复（跨 engine 一致）；模型经代理暴露（规避跨 engine QObject 进 QV4 值系统）；QML 测试框架多 engine 场景不再崩溃。
- 反面：HQ 转发层样板（每类一个新类）；QML 消费面改名（仓库内 17+ 处引用迁移）；`metadata` role 数据缺口保留（源模型 data() 无 MetadataRole case——视图需要元数据时经 theme role 的 Theme.metadata() 读取，已在 ThemeHQModel QDoc 记录）。
