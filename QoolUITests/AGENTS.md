# QoolUITests（测试设施）

QoolUI 的测试设施：Qt Test + Qt Quick Test 双栈程序化测试。本文件是**设施规范与操作守则**——术语、测试单元编写规范、QML 单元组织、CMake 组织、测试策略、运行通道、新增测试步骤。通用 Qt/Windows/CMake 机制（DLL 部署、qt.conf、输出判读、MSYS 管道伪象等）沉淀于 journal，不在此重复。

## 术语表

术语为稳定命名，跨会话、跨文档一律使用全称，禁止简写变体（如「QML 测试批次」不以「批次」简称）。

| 术语 | 定义 |
|---|---|
| **测试设施** | QoolUI 测试体系统称：`QoolUITests` 目录、本规范、CMake 机制与全部运行通道 |
| **测试单元** | 可独立识别与运行的测试粒度。C++ 侧 = 一个 CMake Target；QML 侧 = 单个 `tst_*.qml` 文件（独立子目录，含配套 `tst_*.cpp` 与独立 target） |
| **测试用例** | 单个测试函数。C++ 侧 = Q_SLOT 方法（QOOL_TEST_CASE 声明）；QML 侧 = `test_` 前缀函数 |
| **QML 测试批次** | 一个被测 Qool 模块的全部 QML 测试单元集合，组织形式为模块目录 `tst_<模块>_qml/`（位于 `QoolUITests/` 顶层，与 `common/`/`core/` 平级）；批次内每测试单元一个独立子目录、独立 target |
| **批次目录** | 承载一个 QML 测试批次的模块目录：含该模块全部测试单元子目录；测试资源放各单元目录下 `assets/` 子目录（文件系统相对路径访问）；`assets/` 内文件不得以 `tst_` 开头（避免 QuickTest 递归扫描误当测试） |
| **运行通道** | 测试 exe 的运行入口：QtCreator 测试面板 / run-tests 聚合 target / CTest / 直接运行 exe |

## 架构与分层

```
QoolUITests/
├── CMakeLists.txt          # 总入口：公共函数、qt.conf 策略、run-tests 聚合 target
├── qool_test.hpp           # 宏族（QOOL_TEST_CASE）
├── qt.conf.in              # qt.conf 模板（Windows Qt 前缀解析）
├── common/                 # QoolCommon 纯 C++ 模板库（Qt Test，QCoreApplication）
├── core/                   # Qool 核心 C++ 类型（Qt Test，直接编译被测 .cpp）
├── tst_qool_qml/           # Qool 模块 QML 测试批次
├── tst_qoolcolor_qml/      # Qool.Color 模块 QML 测试批次
└── tst_qoolcontrols_qml/   # Qool.Controls 模块 QML 测试批次
```

**分层与被测面一一对应**：`common` 测脱离 Qool 的纯逻辑（QCoreApplication 即可），`core` 测 Qool 的 C++ 类型，QML 批次（`tst_<模块>_qml/`）测公开 QML 组件的行为契约。测试单元数量与清单以 CMake 声明为准（不在此硬编码，避免漂移）。

## 测试单元编写规范

### 单元与组件一一对应

- 每个测试单元严格对应一个被测类/组件：C++ 侧一个 CMake Target 测一个类，QML 侧一个 `tst_*.qml` 测一个组件；单元名与被测组件同名（`tst_<组件>`）
- 测试范围 = 被测组件的公开契约；被测组件之外的任何对象不属于本单元测试范围——测试它们即越界测试，须删除或迁移到该对象自己的测试单元
- 子元素有独立测试单元的，不在本单元测其行为；子元素无独立测试单元的，不代测——其公开契约测试须专门设计独立单元（先有参考文档定义行为）

### 以参考文档为准绳

- 组件公开行为（属性语义、信号发射条件、方法契约）必须以 reference 文档定义为准绳——实现行为与文档定义不符 = 缺陷（实现或文档二选一打回修正）
- 文档未定义的公开行为无法编写测试用例，打回重做（先补文档定义行为，再写测试）；测试断言与文档冲突时以文档为准并上报文档-实现不一致

### 不测内部实现

- 禁止读内部子组件断言实现：`findChild`/`children`/`data` 数组遍历、内部 ShapePath 坐标、内部状态对象等一律禁止
- 测试外部行为（文档定义的属性读/写/运行、信号发射条件与载荷、方法契约面），不断言实现细节——测试是组件的可执行文档，读者能从测试名与断言推断组件行为

### 不测子元素公开契约 / 不测 Qt 框架组件

- 子元素有自己的参考文档与测试单元，本单元不替子元素验证；需测子元素行为时，在其自己的单元测试中验证
- Qt 模板行为、Qt 控件插拔契约（background/handle 替换机制）等不测——不替 Qt 验证，测试聚焦本项目契约

### 覆盖完整度

- **公开属性必须覆盖全部行为面（读、写、运行）**：每个公开属性至少覆盖——读（默认值/声明值、外部变更后的回读）、写（外部赋值生效、目标对象/派生状态同步）、运行（属性驱动的行为路径实际触发）；readonly 属性须验证「读 + 不可写」；属性默认值与声明一致
- **公开信号必须覆盖发射条件与负载**：每个公开信号至少一个用例验证其发射时机与载荷；无参信号验证「仅实际变化时触发」（如 `xxxChanged` 不随同值赋值重复发射）
- **公开方法必须覆盖全部契约面**：正常调用路径、边界/非法输入路径、返回值正确性、调用后的状态副作用
- **契约裁剪项须显式验证「无」**：组件声明无 `reset`/`defaultValue`/双击等裁剪契约时，测试须显式断言该能力不存在（属性访问 undefined/无对应信号），锁定裁剪不被回填
- **新增/修改公开接口时同步补测试**：实现变更若增删改公开接口，对应测试用例必须同批更新；文档先行——先更新 reference 文档定义行为，再写实现与测试

### 写法规则

- **命名**：测试函数行为化 `snake_case`（C++ 与 QML 统一），函数名即行为文档——`test_<行为>`；禁止 `test_1`/`test_a` 等无意义名
- **数据驱动**（C++）：多输入面用 `_data()` + `QFETCH`；数据行命名 `:行名` 描述场景
- **浮点断言**（C++）：自备 `fuzzy_eq`；fuzzy 容差必须注释论证依据（量化 ULP/float 存储/组件语义），禁止无注释的裸容差
- **信号计数**：锁定精确期望值（`QCOMPARE(spy.count, N)`）；禁止区间断言，除非注释论证环振荡/多落定语义
- **禁止弱断言**：双分支都 verify 通过的写法锁定不了任何行为，禁止；行为面必须单一路径锁定
- **负向断言**：验证「不变化/不跟随」时允许固定 `wait()` 窗口，但必须注释「负向断言必要折衷」+ 窗口时长论证
- **属性/信号契约**（C++）：`QSignalSpy` + 相等守卫断言（同值赋值不发信号）
- **期望 FAIL 测试**：禁止无条件常驻套件——必须 `QEXPECT_FAIL`（C++）/ `expectFail`（QML）显式标记 + 缺陷跟踪；标记注释指向缺陷描述；缺陷修复后由修复者移除标记使测试转绿
- **QML 状态隔离（硬要求）**：TestCase 的各测试函数共享同一实例且按函数名顺序执行——每个测试函数用 `createTemporaryObject(component, root)`（或 `createTemporaryQmlObject`）创建独立实例 + 动态创建 SignalSpy
- **QML 时序断言**：绑定/传播异步，用 `tryCompare(obj, prop, value, timeout)` / `tryVerify` 轮询（内部跑事件循环，Timer 驱动可测）
- **QML 窗口访问**：TestCase 没有 `window` 属性；正确途径是 `Window.window` 附加属性（`import QtQuick.Window`）。引擎 hit-test 端到端验证不可行；掩码/命中类契约改为直接调用掩码对象的 `contains()` 断言（见 tst_crystal.qml 的 `expectContains` 辅助）
- **基准**（C++）：性能契约用 `QBENCHMARK`（tst_math.cpp 有示范）
- **纯逻辑用 QCoreApplication**（QTEST_MAIN 自动选择）；只有真正需要窗口的测试才碰 QPA

### 宏族与测试类文件约束

- 唯一自定义宏 `QOOL_TEST_CASE(_N_)` = `private: Q_SLOT void _N_()`，类体内内联定义（init/cleanup/xxx_data 同宏）；类声明必须显式书写（`class X : public QObject { Q_OBJECT`），宏不包裹类
- 禁止 `private slots:` 区语法入宏——moc 不收集宏内槽区
- main 不包装：无 GUI 用 `QTEST_APPLESS_MAIN`、GUI 用 `QTEST_MAIN`（原生按需选）
- moc include 用显式文件名（`#include "tst_xxx.moc"`）：`QT_MOC` 宏在 CMake AUTOMOC 下不可用
- 不引入自定义 logger：QTest 标准输出足够
- Q_OBJECT 测试类内禁用 `R"(...)"` 原始字符串字面量（moc 解析缺陷，槽丢失链接才爆）——QML 场景字符串一律用普通字符串拼接（多行相邻字面量）

## QML 测试单元组织

- 每个 Qool 模块 = 一个 QML 测试批次 = 一个模块目录（`tst_<模块>_qml/`，位于 `QoolUITests/` 顶层）；批次内每测试单元一个独立子目录（`tst_<组件>/`，含 `tst_<组件>.qml` + 独立 `tst_<组件>.cpp` + 独立 `CMakeLists.txt`）与独立 target
- **每单元独立 `CMakeLists.txt` 是硬前提（MUST）**：一个 CMake `directory`（由 `add_subdirectory` 引入）下只放一个 QML target——否则 Qt Creator `internalTargets(proFile)` 按 projectFile 命中同目录全部 target、弹「选择 executable」。批次文件只做 `add_subdirectory(<单元>)` 列表（单元 CMakeLists 内 `qoolui_add_qml_test(tst_xxx_qml tst_xxx <模块>)`）。新增 QML 单元 = 新建单元目录 + 其 `CMakeLists.txt` + 批次文件加一行 `add_subdirectory`
- 每个测试单元的 `tst_<组件>.cpp` 独享 `QUICK_TEST_SOURCE_DIR` 编译宏（绝对路径指向自己单元目录）——Qt Creator 的 QuickTest 扫描器从 CMake project macros 读取该宏定位 QML 目录；**一个 cpp 只被一个 target 编译（一 cpp 一 target 一宏值）是「exe ↔ QML 目录」关联无歧义的硬前提**
- 新增 QML 测试单元：调用 `qoolui_add_qml_test()` 辅助函数（add_executable + 链接 + offscreen 参数登记 + add_test + 注册表 + DLL 部署 + LINK_DEPENDS）——零样板
- **测试文件运行期扫描加载**（`QUICK_TEST_SOURCE_DIR` 指向源码目录，target 只编译 `tst_*.cpp`）：修改 `tst_*.qml` 无需重链/无需构建，直接跑 exe 即加载新文件；新增 `tst_*.qml` 运行期自动发现。ninja 报 "no work to do" 是正确行为
- **库 QML 改动需重建**（与上条区分）：改 `tst_*.qml` 即时生效，但改库模块源码（`QoolUI/QoolControls/*.qml`、`Qool/Qool/*.qml` 等）必须 build 重建模块 + 重链测试 target 才生效（LINK_DEPENDS 机制保证副本同步）——改动库组件后直接跑 exe 会按旧实现跑

## 测试策略

- **Qool.Debug 不自动测试**：其边界条件（除零/最小尺寸/越界）有意暴露使用问题（边界暴露原则）——编译无误 + 手动验证即可
- **并行运行确定性**：`ctest -j` 可用，无需架构改动——每个测试是独立进程（独立 QGuiApplication/渲染上下文/内存），offscreen 软件渲染无 GPU 争抢；CI `-j` 别开满（每 QML 测试进程几十 MB）
- **覆盖策略**：用例以组件公开接口声明为清单，覆盖全部公开方法/信号/属性的读、写、运行行为（见「覆盖完整度」）

## CMake 组织

- **自包含**：本树位于仓库顶级，不继承 QoolUI 的 `qt_standard_project_setup()` 目录作用域——`CMAKE_AUTOMOC`、`project()` 自行声明
- **project 声明**：`project(QoolUITests VERSION ${QOOLUI_VERSION_FULL} LANGUAGES CXX)`——子目录 project() 重置 PROJECT_* 变量，本树引用模块路径一律相对路径（`${CMAKE_CURRENT_LIST_DIR}/../../QoolUI/...`）
- **CTest 注册**：`include(CTest)` 在主 CMakeLists 的 `if(QOOL_BUILD_TESTS)` 内（顶层启用——enable_testing 必须顶层调用，`ctest --preset dev-<kit>-<type>` 才能在 `build/build-<kit>-<Type>/` 找到 CTestTestfile.cmake 并递归发现本树测试）；`BUILD_TESTING` = 注册侧标准开关（OFF 时测试仍构建但 ctest 不注册，run-tests 仍可用）
- **输出树**：`build/build-<kit>-<Type>/QoolUITests/{common,core,<模块批次>}` 各层（层内共享一份 DLL 集，`copy_if_different` 幂等）；目录级 `CMAKE_RUNTIME_OUTPUT_DIRECTORY` 覆盖不碰主设置
- **qt.conf**（Windows 前缀解析，仅 `if(WIN32)` 生成）：`qt.conf.in` 配置期生成到各层 exe 旁（`Prefix = Qt 安装前缀`，绝对路径正斜杠）——QLibraryInfo 读取，覆盖 DLL 复制导致的推导失效；任何运行通道无需环境注入；源码不含安装路径。common 层不需要（纯 QCoreApplication）；QML 批次与 core 层需要。Linux/macOS 跳过（生成反而破坏 QLibraryInfo 推导）。改模板后需重新 configure 生效。机制细节见 journal
- **DLL 部署**（Windows，`if(WIN32)` 包裹）：POST_BUILD `$<TARGET_RUNTIME_DLLS>` 复制 Qt DLL；QML 批次额外复制被测模块 target 的 RUNTIME_DLLS + TARGET_FILE。非 Windows 分支：`$<TARGET_RUNTIME_DLLS>` 展开为空，只复制模块库本体
- **构建开关**（`load_qoolui_standard_options()`，默认 ON）：`QOOL_BUILD_TESTS` = 构建侧总闸（OFF 时测试树彻底消失含 include(CTest)）；`BUILD_TESTING` = 注册侧标准开关
- **EXCLUDE_FROM_ALL**：测试 target 加入默认构建（all）——面板运行前构建 all，被排除测试的 exe 缺失会导致「启动测试失败」全红
- **注册机制**：`qoolui_add_cpp_test()` 公共函数（add_executable + Qt6::Test + add_test + DLL 部署 + 注册表）；`qoolui_add_qml_test()` 公共函数（add_executable + Qt6::QuickTest/Qt6::Qml + offscreen 参数登记 + add_test + 注册表 + DLL 部署 + LINK_DEPENDS）；`QOOLUI_TEST_TARGETS` 注册表驱动 run-tests 聚合 target；common 层 `file(GLOB CONFIGURE_DEPENDS)` 自动发现，core 层显式注册（需声明被测源，刻意）；测试特定参数经 `QOOLUI_TEST_ARGS_<target>`

## 运行通道

| 通道 | 命令 | 适用 |
|---|---|---|
| 聚合 target（日常） | `cmake --build build/build-<kit>-<Type> --target run-tests` | 一条命令跑全部、失败即红 |
| CTest | `ctest --preset dev-<kit>-<type>`（或 `ctest -R tst_`） | CI/筛选/并行/报告 |
| 直接运行 | `build/build-<kit>-<Type>/QoolUITests/<层>/tst_*.exe -txt` | 单个测试调试；QML 加 `-platform offscreen` 无头 |

**ctest 筛选**：单个 `ctest -R tst_qool_vector2d`；QML 全量 `ctest -R "tst_.*_qml"`；按批次 `ctest -R "tst_qool_.*_qml"`（QML 单元 target 均以 `_qml` 结尾）；CTest 正则不支持 `|` 交替，多组筛选分开跑或只保留共同前缀。失败重跑 `ctest --rerun-failed`；CI 报告 `ctest --output-junit result.xml`（配合 `--output-on-failure`）。

**Windows 一键**（环境+配置+构建+测试）：

```bash
python Scripts/qoolui_build_windows.py configure --qt C:/Qt/6.11.1   # 首次必带 --qt（脚本内置 vcvars/MinGW 环境准备）
python Scripts/qoolui_build_windows.py build
python Scripts/qoolui_build_windows.py test                          # ctest 聚合，输出落盘 build/build-<kit>-<Type>/test.log
```

MinGW 工具链加 `--kit gcc`。`run`（启动 QoolUIExample）同需 `--qt`（或环境 `QT_DIR`）。一键操作流程的唯一事实源在此（根 AGENTS.md 仅一行引用）。

**平台差异**：Linux/macOS 系统 Qt 在标准路径，无需 DLL 部署/插件注入/`QT_PLUGIN_PATH`——`if(WIN32)` 之外零逻辑，configure/build/test 用对应 kit 的 preset（kit 按工具链选，矩阵见根 AGENTS.md「构建命令」）。CI 无头：QML 测试已内置 `-platform offscreen`；Linux CI 若需可再加 `QT_QPA_PLATFORM=offscreen`。

**判读测试输出**：Qt Test 结果走 stdout，Qt 消息走 stderr；QML 测试结果默认不进 stdout（须 `-o <file>,txt` 落盘读文件）。MSYS/bash 环境会吞 stdout 且退出码不可信——判读走 eval 内核 python subprocess + 文件重定向，或真实终端，勿在 bash 里判读。细节见 journal。

## 如何新增测试

### C++ 测试（QoolCommon / Qool 核心类型）

1. 在对应子目录建 `tst_<对象>.cpp`，类名 `Test<对象>`；测试用例用宏族 `QOOL_TEST_CASE(test_xxx)` 类体内内联定义（`#include "qool_test.hpp"`）；结尾 `QTEST_MAIN(TestXxx)` + `#include "tst_xxx.moc"`（AUTOMOC 自动处理）
2. 注册（按层区分）：
   - **QoolCommon（common/）**：零配置——`file(GLOB CONFIGURE_DEPENDS)` 自动发现，新文件放进目录即进入构建/CTest/run-tests；不要手动写 `qoolui_add_cpp_test`（会与 GLOB 重复生成同名 target 导致构建失败）
   - **Qool 核心类型（core/）**：在 `core/CMakeLists.txt` 显式注册 `qoolui_add_cpp_test(tst_qool_<对象> tst_<对象>.cpp <被测源 .cpp>)` + `target_link_libraries(... PRIVATE Qool QoolCommon QoolUITestSupport Qt6::Quick)`——不链接 Qool target 取实现（Qool 是 DLL 且按仓库原则不导出 C++ 符号），把被测 `.cpp` 直接编入测试 target 仅取头文件路径。必须补 PRIVATE include：`target_include_directories(tst_qool_<对象> PRIVATE ${QOOL_SRC_PRIVATE_INCLUDES})`——被测头内部可能引用 Qool 模块的 PRIVATE include 目录下的头（`gadgets/*.h`、`qool_smartobj.h`、`qool_literals.h` 等），这些目录不随 Qool target 传播。清单在 `core/CMakeLists.txt` 顶部定义，与 `Qool/CMakeLists.txt` 的 PRIVATE include 同步维护
3. 测试风格约定：数据驱动 `_data()` + `QFETCH`；浮点断言自备 `fuzzy_eq`；属性/信号契约 `QSignalSpy` + 相等守卫；基准 `QBENCHMARK`；纯逻辑用 QCoreApplication

### QML 测试（按 Qool 模块分 QML 测试批次）

1. 在对应模块的批次目录下建单元子目录 `tst_<组件>/`，内含 `tst_<组件>.qml`：`import QtQuick; import QtTest; import Qool` + `TestCase { name: ... }`
2. 同目录建 `tst_<组件>.cpp`（复制现有单元 cpp 模板：`QUICK_TEST_MAIN_WITH_SETUP` + QoolTestSetup 注入 `QOOLUI_TEST_QML_IMPORT_PATH`）——一 cpp 一 target 一宏值
3. 建单元 `CMakeLists.txt` 调用 `qoolui_add_qml_test(tst_<组件>_qml tst_<组件> <模块依赖...>)`，在批次 `CMakeLists.txt` 加一行 `add_subdirectory(tst_<组件>)`——独立 target 自动进入构建/CTest/run-tests/面板；Qool 模块 import path 已注入（`QOOLUI_TEST_QML_IMPORT_PATH` → `build/build-<kit>-<Type>/qml`）
4. 测试资源放单元目录 `assets/` 子目录（文件系统相对路径访问）；`assets/` 内不得有 `tst_` 前缀文件（递归扫描误判）
5. 每个测试函数用 `createTemporaryObject` 创建独立实例 + 动态 SignalSpy（状态隔离硬要求）
6. 时序断言用 `tryCompare`（内部跑事件循环，Timer 驱动可测）
7. `import Qool` 走运行时解析：QML 测试文件不参与 qmlcachegen AOT，无需改模块 CMake
8. 窗口访问用 `Window.window` 附加属性；引擎 hit-test 不可行时改调掩码对象 `contains()` 断言
9. **新增整个测试批次**（新模块的 `tst_<模块>_qml` 批次目录）：建批次目录 + CMakeLists（qt.conf + `qoolui_add_qml_test` 注册各单元），在 `QoolUITests/CMakeLists.txt` 加 `add_subdirectory`
