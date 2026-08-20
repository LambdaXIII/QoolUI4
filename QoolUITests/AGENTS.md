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


## 测试方法规范

### 宏族与测试类文件约束

- 唯一自定义宏 `QOOL_TEST_CASE(_N_)` = `private: Q_SLOT void _N_()`，类体内内联定义（init/cleanup/xxx_data 同宏）；类声明必须显式书写（`class X : public QObject { Q_OBJECT`），宏不包裹类
- 禁止 `private slots:` 区语法入宏——moc 不收集宏内槽区（槽丢失，测试表现为仅 init/cleanup 通过）
- main 不包装：无 GUI 用 `QTEST_APPLESS_MAIN`、GUI 用 `QTEST_MAIN`（原生按需选）
- moc include 用显式文件名（`#include "tst_xxx.moc"`）：`QT_MOC` 宏在 CMake AUTOMOC 下不可用（CMake 4.4.2 文档无 QT_MOC 支持，AUTOMOC 只识别字面 `#include "xxx.moc"`）
- 不引入自定义 logger：QTest 标准输出足够
- **Q_OBJECT 测试类内禁用 `R"(...)"` 原始字符串字面量**（moc 解析缺陷）：函数体原始字符串内容含 `"#..."` 或 `//` 注释时，moc 报「No relevant classes found」、Q_OBJECT 类不被收集——编译期无错、链接才爆（缺 metaObject/qt_metacall 符号）。QML 场景字符串一律用普通字符串拼接（多行相邻字面量）

### 断言与隔离

- 浮点断言自备 `fuzzy_eq`（QCOMPARE 浮点是精确比较）；属性/信号契约用 `QSignalSpy` + 相等守卫断言
- **compare/verify 第三参避免非 ASCII**（QML 引擎 bug）：第三参含中文等非 ASCII 时测试**加载期静默失败**（rc 3 无输出、无 Totals、无 initTestCase），英文第三参正常；**注释**（`//`）不受限
- **QML 颜色断言用 `toString()`**（QML color 值类型无 `.name` 属性——QColor 的 C++ 属性未暴露）：`.name` 恒 undefined，且 `compare(undefined, undefined)` **假 PASS** 掩盖断言失效；用 `tryVerify(function(){ return s.color.toString() === "#rrggbb" })` 规范化比较

### QML 测试批次组织

- 每个 Qool 模块 = 一个 QML 测试批次 = 一个 harness target（`tst_<模块>_qml`），`assets/` 资源放批次目录下（文件系统相对路径访问，如 `"assets/foo.png"`）；`assets/` 内不得有 `tst_` 前缀文件
- 新增 QML 测试批次：复制 `qml/CMakeLists.txt` 的 tst_qool_qml 段（add_executable + 编译定义 + add_test + 注册表登记），QUICK_TEST_SOURCE_DIR 指向新批次目录
- harness 共享 `qml_test_main.cpp` 模板；import path 不必按模块区分（`QT_QML_OUTPUT_DIRECTORY = build/build-<kit>-<Type>/qml` 全局，引擎沿模块依赖链自动解析）
- **测试文件运行期扫描加载**（`QUICK_TEST_SOURCE_DIR` 指向源码目录，harness target 只编译 `qml_test_main.cpp`）：修改 `tst_*.qml` **无需重链/无需构建**，直接跑 exe 即加载新文件；新增 `tst_*.qml` 运行期自动发现。测试文件不在 CMake 依赖图内——ninja 报 "no work to do" 是正确行为，勿误判为需删 exe 强制重链（qml 内容变化永远即时生效）
- **库 QML 改动需重建**（与上条区分）：改 `tst_*.qml` 即时生效，但改**库模块源码**（`QoolUI/QoolControls/*.qml`、`Qool/Qool/*.qml` 等）**必须 `build` 重建模块 + 重链 harness** 才生效——改动库组件后直接跑 exe 会按旧实现跑，勿误判「代码没生效/错了」
- **QML 测试文件修改用 edit 工具**：勿整文件 python 重写（引入 CRLF/LF 行尾噪音，git diff 全文件变化）；确需脚本重写时 git diff 用 `-w` 复核真实差异

## 测试策略

- **Qool.Debug 不自动测试**：其边界条件（除零/最小尺寸/越界）有意暴露使用问题（`QoolUI/QoolDebug/AGENTS.md` 边界暴露原则）——编译无误 + 手动验证即可
- **并行运行确定性**：`ctest -j` 可用，无需架构改动——每个测试是独立进程（独立 QGuiApplication/渲染上下文/内存），offscreen 软件渲染无 GPU 争抢。运维注意：CI `-j` 别开满（每 QML harness 进程几十 MB）
- **覆盖策略**：现阶段仅调整框架；覆盖优先级另议（推迟）

## 工作流

- **测试工作流**（SHOULD）：验证强度分级见根 `AGENTS.md`「验证策略」——全量 `test` 脚本（`python Scripts/qoolui_build_windows.py test`）是「完整落地一套修改」的收尾回归哨兵，**非默认动作**；小改动按分级模型选通道（针对性单测试 `ctest -R` / 用户运行验证 / 编译 build）
- **摩擦求助**（MUST）：摩擦定义为「无法运行测试用例」；多次尝试无法解决 → 暂停测试求助用户
- **摩擦反馈回路**（SHOULD）：测试后若发生摩擦，总结摩擦点并提出 Tests 规范改进方案，交用户批准（不自动改）；已定案的摩擦与规避**就地沉淀到本规范相应小节**（如「输出验证」「断言与隔离」「QML 测试批次组织」），不散落到临时文件

## CMake 组织（as-shipped）

- **自包含**：本树位于仓库顶级，不继承 QoolUI 的 `qt_standard_project_setup()` 目录作用域——`CMAKE_AUTOMOC`、`project()` 自行声明
- **project 声明**：`project(QoolUITests VERSION ${QOOLUI_VERSION_FULL} LANGUAGES CXX)`——子目录 project() 重置 PROJECT_* 变量，本树引用模块路径一律相对路径（`${CMAKE_CURRENT_LIST_DIR}/../../QoolUI/...`），不引用 QoolUI 的 PROJECT_*
- **CTest 注册**：`include(CTest)` 在主 CMakeLists 的 `if(QOOL_BUILD_TESTS)` 内（顶层启用——enable_testing 必须顶层调用，`ctest --preset dev-<kit>-<type>` 才在 `build/build-<kit>-<Type>/` 找到 CTestTestfile.cmake 并递归发现本树测试）；`BUILD_TESTING` = 注册侧标准开关（OFF 时测试仍构建但 ctest 不注册，run-tests 仍可用）
- **输出树**：`build/build-<kit>-<Type>/QoolUITests/{common,core,qml}` 三层（层内共享一份 DLL 集，`copy_if_different` 幂等）；目录级 `CMAKE_RUNTIME_OUTPUT_DIRECTORY` 覆盖不碰主设置
- **qt.conf**（Windows 前缀解析，仅 `if(WIN32)` 生成）：`qt.conf.in` 配置期生成到 core/qml 层 exe 旁（`Prefix = Qt 安装前缀`，绝对路径正斜杠）——QLibraryInfo 读取，覆盖 DLL 复制导致的推导失效；任何运行通道无需环境注入；源码不含安装路径。**common 层不需要**（纯 QCoreApplication，不加载平台插件）；core 层需要（链接 Qt6::Quick → QGuiApplication 构造加载平台插件）。Linux/macOS 跳过（系统 Qt 标准路径，生成反而破坏 QLibraryInfo 推导）。改模板后需重新 configure 生效
- **DLL 部署**（Windows，`if(WIN32)` 包裹）：POST_BUILD `$<TARGET_RUNTIME_DLLS>` 复制 Qt DLL；qml 层额外复制 Qool/QoolControls/QoolControlsComponents target 的 RUNTIME_DLLS + TARGET_FILE（Qoolplugin.dll 从 `build/build-<kit>-<Type>/qml/Qool/` 加载，其依赖链须在 exe 目录）。非 Windows 分支：`$<TARGET_RUNTIME_DLLS>` 展开为空（裸用会令 `copy_if_different` 缺参报错），只复制 qml 层三个模块库本体
- **构建开关**（`load_qoolui_standard_options()`，默认 ON）：`QOOL_BUILD_TESTS` = 构建侧总闸（测试目录是否加入，OFF 时测试树彻底消失含 include(CTest)）；`QOOL_BUILD_EXAMPLEAPP` = 示例程序；`BUILD_TESTING`（顶层 include(CTest) 提供）= 注册侧标准开关（OFF 时测试仍构建但 ctest 不注册，run-tests 仍可用）
- **EXCLUDE_FROM_ALL**：测试 target **加入默认构建（all）**——原「EXCLUDE_FROM_ALL 不构建测试」设计被 QtCreator 面板通道行为推翻：面板运行前构建 all，被排除测试的 exe 缺失 → 「启动测试失败/无预期输出」全红。run-tests 保留为聚合运行通道（DEPENDS 常规依赖）。QtCreator 面板列出可运行（从 CMake target 数据库读）
- **注册机制**：`qoolui_add_cpp_test()` 公共函数（add_executable + Qt6::Test + add_test + DLL 部署 + 注册表）；`QOOLUI_TEST_TARGETS` 注册表驱动 run-tests 聚合 target；common 层 `file(GLOB CONFIGURE_DEPENDS)` 自动发现，core 层显式注册（需声明被测源，刻意）；测试特定参数经 `QOOLUI_TEST_ARGS_<target>`

## 运行通道

| 通道 | 命令 | 适用 |
|---|---|---|
| 聚合 target（日常） | `cmake --build build/build-<kit>-<Type> --target run-tests` | 一条命令跑全部、失败即红，无 CTest 机制 |
| CTest | `ctest --preset dev-<kit>-<type>`（或 `ctest -R tst_`） | CI/筛选/并行/报告 |
| 直接运行 | `build/build-<kit>-<Type>/QoolUITests/<层>/tst_*.exe -txt` | 单个测试调试；QML 加 `-platform offscreen` 无头；单文件用 `-input <绝对路径>` |

Windows 一键（环境+配置+构建+测试）操作流程见 `README.md`（`python Scripts/qoolui_build_windows.py` 三次调用，唯一事实源）。

### 输出验证（Qt Test stdout）

- Qt Test 测试结果（PASS/FAIL/FAIL! 详情）走 **stdout**；Qt 消息（QDEBUG/QINFO/QWARN、QML debugging 提示）走 stderr
- **通道分级（MSYS 管道伪象是元问题）**：MSYS/bash 工具环境会吞 Qt Test 的 stdout（文件重定向得 0 字节、退出码不可信、bash 内 python subprocess 捕获为空），还会破坏 `-input` 的 Windows 盘符路径（`D:/...` 被解析成函数名 `D()`）——**这些不是测试或设施缺陷，是观测通道问题，勿误诊成「测试没跑/缺 env/路径错」**
  - **可靠**：eval 内核 python subprocess + `stdout=open(tmp,"wb")` 文件重定向（真实 CreateProcess，不受 MSYS 影响）；真实终端（cmd/PowerShell/PTY）；直接运行 `exe -input <绝对路径> -platform offscreen`
  - **不可靠**：MSYS bash 直接跑 exe、bash 内 python 脚本的 subprocess stdout 捕获（rc 可信、stdout 不可信）——测试输出验证一律走 eval 内核或真实终端，不在 bash 里判读
- ctest `--output-on-failure`（testPresets 已配置 `outputOnFailure:true`）在可靠通道下失败时完整透出聚合 exe 内部 FAIL! 详情（Actual/Expected/location）

## 已知经验（Windows 特有，供跨平台对照）

Windows 环境经验唯一清单（MSYS 管道伪象/Ninja POST_BUILD 竞争/Qt 前缀定位/CTest ENVIRONMENT 陷阱/AUTOGEN 残留等）见 `README.md`——本规范不再重复维护。
