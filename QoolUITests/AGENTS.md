# QoolUITests（测试设施）

QoolUI 的测试设施：Qt Test + Qt Quick Test 双栈程序化测试。本文件是**设施规范**（术语、方法、策略、CMake 组织定案）；使用手册见同目录 `README.md`。

## 术语表

术语为稳定命名，跨会话、跨文档一律使用全称，禁止简写变体（如「QML 测试批次」不以「批次」简称）。

| 术语 | 定义（含表现形式） |
|---|---|
| **测试设施** | QoolUI 测试体系统称：`QoolUITests` 目录、本规范、CMake 机制与全部运行通道 |
| **测试单元** | 可独立识别与运行的测试粒度。C++ 侧 = 一个 CMake Target（QTEST_MAIN 单类，QtCreator 可选单元前提）；QML 侧 = 单个 `tst_*.qml` 文件 |
| **测试用例** | 单个测试函数。C++ 侧 = Q_SLOT 方法（QOOL_TEST_CASE 声明）；QML 侧 = `test_` 前缀函数 |
| **QML 测试批次** | 一批 QML 测试单元的集合，组织形式为独立 CMake Target（一个 harness exe），命名 `tst_<模块>_qml`；每个 QML 测试批次对应一个被测 Qool 模块，拥有独立批次目录 |
| **批次目录** | 承载一个 QML 测试批次的目录：含该 QML 测试批次全部 `tst_*.qml` 与 `assets/` 资源子目录；`assets/` 内文件不得以 `tst_` 开头（避免被 harness 递归扫描误当测试） |
| **harness** | QML 测试宿主程序：`QUICK_TEST_MAIN_WITH_SETUP` 展开的可执行文件，扫描批次目录、加载并执行测试单元；共享源码模板 `qml_test_main.cpp`，多个 QML 测试批次各自编译 |
| **运行通道** | 测试 exe 的运行入口：QtCreator 测试面板 / run-tests 聚合 target / CTest / 直接运行 exe |
| **轮询断言** | 异步与时序验证的唯一允许断言形式：`tryCompare`/`tryVerify` 带超时轮询；禁止固定 `sleep` |
| **状态隔离** | QML 测试编写规范：每测试用例以 `createTemporaryObject`（Component 创建）或 `createTemporaryQmlObject`（QML 源码字符串创建）创建独立临时实例，防止状态跨测试用例泄漏 |

## 测试方法规范

### 宏族（qool_test.hpp）

- 唯一自定义宏 `QOOL_TEST_CASE(_N_)` = `private: Q_SLOT void _N_()`，类体内内联定义（init/cleanup/xxx_data 同宏）；类声明必须显式书写（`class X : public QObject { Q_OBJECT`），宏不包裹类
- 禁止 `private slots:` 区语法入宏——moc 不收集宏内槽区（槽丢失，测试表现为仅 init/cleanup 通过）
- main 不包装：无 GUI 用 `QTEST_APPLESS_MAIN`、GUI 用 `QTEST_MAIN`（原生按需选）
- moc include 用显式文件名（`#include "tst_xxx.moc"`）：`QT_MOC` 宏在 CMake AUTOMOC 下不可用（实测，2026-08-12——CMake 4.4.2 文档无 QT_MOC 支持，AUTOMOC 只识别字面 `#include "xxx.moc"`）
- 不引入自定义 logger：QTest 标准输出足够

### 断言与隔离

- **轮询断言**：异步与时序验证一律 `tryCompare(obj, prop, value, timeout)` / `tryVerify`（内部跑事件循环），不写固定 `sleep`；超时给足。与并行无关——并行只是放大脆弱测试的弱点
- **状态隔离**：TestCase 各测试函数共享同一实例且按函数名顺序执行——共享状态会跨测试泄漏。每个测试函数用 `createTemporaryObject`（或 `createTemporaryQmlObject`）创建独立实例 + 动态创建 SignalSpy（见 tst_timerlatch.qml 的 makeLatch/makeSpy）
- 浮点断言自备 `fuzzy_eq`（QCOMPARE 浮点是精确比较）；属性/信号契约用 `QSignalSpy` + 相等守卫断言

### QML 测试批次组织

- 每个 Qool 模块 = 一个 QML 测试批次 = 一个 harness target（`tst_<模块>_qml`），`assets/` 资源放批次目录下（文件系统相对路径访问，如 `"assets/foo.png"`）；`assets/` 内不得有 `tst_` 前缀文件
- 新增 QML 测试批次：复制 `qml/CMakeLists.txt` 的 tst_qool_qml 段（add_executable + 编译定义 + add_test + 注册表登记），QUICK_TEST_SOURCE_DIR 指向新批次目录
- harness 共享 `qml_test_main.cpp` 模板；import path 不必按模块区分（`QT_QML_OUTPUT_DIRECTORY = build/qml` 全局，引擎沿模块依赖链自动解析）

## 测试策略

- **Qool.Debug 不自动测试**：其边界条件（除零/最小尺寸/越界）有意暴露使用问题（根 AGENTS.md「Debug 工具边界暴露原则」）——编译无误 + 手动验证即可
- **并行运行确定性**：`ctest -j` 可用，无需架构改动——每个测试是独立进程（独立 QGuiApplication/渲染上下文/内存），offscreen 软件渲染无 GPU 争抢。运维注意：CI `-j` 别开满（每 QML harness 进程几十 MB）
- **覆盖策略**：现阶段仅调整框架；覆盖优先级另议（推迟）

## CMake 组织（as-shipped）

> 注释中的「原 spec N.M」指已归档的落地 spec（.scratch 已删除），编号保留供追溯（journal 记录）；定案一律以本文件为准。

- **自包含**：本树位于仓库顶级，不继承 QoolUI 的 `qt_standard_project_setup()` 目录作用域——`CMAKE_AUTOMOC`、`project()` 自行声明
- **project 声明**：`project(QoolUITests VERSION ${QOOLUI_VERSION_FULL} LANGUAGES CXX)`——子目录 project() 重置 PROJECT_* 变量，本树引用模块路径一律相对路径（`${CMAKE_CURRENT_LIST_DIR}/../../QoolUI/...`），不引用 QoolUI 的 PROJECT_*
- **CTest 注册**：`include(CTest)` 在主 CMakeLists 的 `if(QOOL_BUILD_TESTS)` 内（顶层启用——enable_testing 必须顶层调用，ctest --preset dev 才在 build/ 找到 CTestTestfile.cmake 并递归发现本树测试；落地实测：内聚到本树时全新 configure 后 ctest 找不到测试，修正为顶层条件化）；`BUILD_TESTING` = 注册侧标准开关（OFF 时测试仍构建但 ctest 不注册，run-tests 仍可用）
- **输出树**：`build/QoolUITests/{common,core,qml}` 三层（层内共享一份 DLL 集，`copy_if_different` 幂等）；目录级 `CMAKE_RUNTIME_OUTPUT_DIRECTORY` 覆盖不碰主设置
- **qt.conf**（Windows 前缀解析，spec 5.2）：`qt.conf.in` 配置期生成到 core/qml 层 exe 旁（`Prefix = Qt 安装前缀`，绝对路径正斜杠）——QLibraryInfo 读取，覆盖 DLL 复制导致的推导失效；任何运行通道无需环境注入；源码不含安装路径。**common 层不需要**（纯 QCoreApplication，不加载平台插件）；core 层需要（链接 Qt6::Quick → QGuiApplication 构造加载平台插件）。改模板后需重新 configure 生效
- **DLL 部署**：POST_BUILD `$<TARGET_RUNTIME_DLLS>` 复制 Qt DLL；qml 层额外复制 Qool target 的 RUNTIME_DLLS + TARGET_FILE（Qoolplugin.dll 从 build/qml/Qool/ 加载，其依赖链须在 exe 目录）
- **构建开关**（`load_qoolui_standard_options()`，默认 ON）：`QOOL_BUILD_TESTS` = 构建侧总闸（测试目录是否加入，OFF 时测试树彻底消失含 include(CTest)）；`QOOL_BUILD_EXAMPLEAPP` = 示例程序；`BUILD_TESTING`（顶层 include(CTest) 提供）= 注册侧标准开关（OFF 时测试仍构建但 ctest 不注册，run-tests 仍可用）
- **EXCLUDE_FROM_ALL（已修正，原 spec 6.3）**：测试 target **加入默认构建（all）**——原「EXCLUDE_FROM_ALL 不构建测试」设计被 QtCreator 面板通道实测推翻：面板运行前构建 all，被排除测试的 exe 缺失 → 「启动测试失败/无预期输出」全红（实验：单测进 all 后绿、其余全红，确认根因）。run-tests 保留为聚合运行通道（DEPENDS 常规依赖）。QtCreator 面板列出可运行（从 CMake target 数据库读）
- **注册机制**：`qoolui_add_cpp_test()` 公共函数（add_executable + Qt6::Test + add_test + DLL 部署 + 注册表）；`QOOLUI_TEST_TARGETS` 注册表驱动 run-tests 聚合 target；common 层 `file(GLOB CONFIGURE_DEPENDS)` 自动发现，core 层显式注册（需声明被测源，刻意）；测试特定参数经 `QOOLUI_TEST_ARGS_<target>`

## 运行通道

| 通道 | 命令 | 适用 |
|---|---|---|
| 聚合 target（日常） | `cmake --build build --target run-tests` | 一条命令跑全部、失败即红，无 CTest 机制 |
| CTest | `ctest --preset dev`（或 `ctest -R tst_`） | CI/筛选/并行/报告 |
| 直接运行 | `build/QoolUITests/<层>/tst_*.exe -txt` | 单个测试调试；QML 加 `-platform offscreen` 无头 |

Windows 一键（配置+构建+测试）：`pwsh -File scripts/win_build_test.ps1`。

## 已知经验（Windows 特有，供跨平台对照）

1. **MSYS/Git-Bash 管道伪象（重大）**：从 MSYS bash 管道运行 Qt Test 程序，stdout logger 输出完全丢失且退出码不可信（表现为「无声退出 0」或虚假的 0xC0000409 崩溃）。**判定测试结果必须从真实 Windows 控制台（cmd/Windows Terminal/PTY）运行**——观测通道问题，不是测试或 Qt 的问题
2. **Ninja 并行 POST_BUILD 竞争**：多个测试 target 的 POST_BUILD 并发复制同一目录（如 plugins/platforms）可能 Permission denied——重跑增量构建即可（本设施已消除该复制，仅当新增同类复制时注意）
3. **Qt 前缀定位**：`${Qt6_DIR}/../../..` = Qt 安装前缀（Qt6_DIR = `<前缀>/lib/cmake/Qt6`）
4. **CTest 的 ENVIRONMENT 陷阱**：`ENVIRONMENT` 属性 PATH 值在 Windows 按 `;` 拆分，多路径注入损坏——不要用；本设施零环境注入（qt.conf）
5. **AUTOGEN 状态残留（C1083 排查）**：测试 target 的源文件列表经历过「空 → 有」的 configure（如中间版本配置错误导致 add_executable 无源）后，autogen timestamp 可能残留为最新（比源文件新）→ 后续正确 configure 不重置 autogen → 构建跳过 moc 生成 → `fatal error C1083: "tst_xxx.moc": No such file or directory`（build.make 中该 target 无 moc 规则可佐证）。**修复：删除构建目录中对应测试目录（如 `build/.../QoolUITests`）强制重新 configure**——仅重跑 cmake 不重置（实测）
