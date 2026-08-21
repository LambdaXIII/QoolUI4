# QoolUI 测试设施

Qt Test + Qt Quick Test 双栈程序化测试设施。本文件是**使用手册**（如何写/跑测试）与**平台经验记录**（Windows 的坑与解法，msvc/mingw 双工具链通用，供其它平台对照）；术语、方法规范、策略与 CMake 组织定案见同目录 `AGENTS.md`。

## 架构

```
QoolUITests/
├── CMakeLists.txt          # 总入口：公共函数、qt.conf 策略、run-tests 聚合 target
├── qool_test.hpp           # 宏族（QOOL_TEST_CASE）
├── qt.conf.in              # qt.conf 模板（Windows Qt 前缀解析）
├── common/                 # QoolCommon 纯 C++ 模板库（Qt Test，QCoreApplication）
│   ├── CMakeLists.txt      # file(GLOB CONFIGURE_DEPENDS) 零配置自动发现
│   ├── tst_math.cpp            # target: tst_math            math 全套：数据驱动 + 边界 + QBENCHMARK 示范
│   └── tst_property_macros.cpp # target: tst_property_macros 属性宏体系：默认值/守卫信号/批量生成契约
├── core/                   # Qool 核心 C++ 类型（Qt Test，直接编译被测 .cpp）
│   ├── CMakeLists.txt      # 显式注册（每个测试声明被测源，刻意）
│   ├── tst_vector2d.cpp            # target: tst_qool_vector2d            值类型：构造/运算符/转换/属性契约
│   ├── tst_numberranger.cpp        # target: tst_qool_numberranger        属性宏体系：默认值/守卫信号/校验逻辑/Q_PROPERTY 契约
│   ├── tst_polar2d.cpp             # target: tst_qool_polar2d             Polar2D：转换/乘除/运算语义
│   ├── tst_multirowselectionmodel.cpp # target: tst_qool_multirowselectionmodel 模型：行选择状态/信号契约
│   └── tst_rectgadget.cpp          # target: tst_qool_rectgadget          RectGadget：九点/半区矩形/内接外接正方形派生几何
└── qml/                    # QML 测试批次层（Qt Quick Test harness）
    ├── CMakeLists.txt
    ├── qml_test_main.cpp   # 共享 harness 模板（QUICK_TEST_MAIN_WITH_SETUP）
    └── tst_qool_qml/       # Qool 模块的 QML 测试批次目录（每模块一个 QML 测试批次）
        ├── tst_timerlatch.qml     # 组件行为：声明式状态/信号/时序（createTemporaryObject 隔离）
        ├── tst_positionlocker.qml # PositionLocker：目标/偏移动态跟随
        ├── tst_cutsizebinding.qml # CutSizeBinding：尺寸/圆角绑定传播
        ├── tst_dummyitem.qml      # 基准组件：测试设施自身用（属性回显/信号记录）
        ├── tst_crystal.qml        # Crystal：默认状态/cutSize 派生/掩码契约（contains 直接调用）
        ├── tst_halfcrystal.qml    # HalfCrystal：方向切换/形态几何（四向三角 + 菱形）/内描边/implicit 钉定契约
        └── assets/             # QML 测试批次资源（不得有 tst_ 前缀文件）
```

**规模口径**：测试单元共 **14 个**（C++ 侧按 CMake Target 计 8 个——common 2 + core 6；QML 侧按 `tst_*.qml` 文件计 6 个）。CTest 注册 **9 个测试**：8 个 C++ target 各 1 个 + 6 个 QML 单元并入 1 个 harness target（`tst_qool_qml`）。

**分层与被测面一一对应**：`common` 测脱离 Qool 的纯逻辑（QCoreApplication 即可），`core` 测 Qool 的 C++ 类型，`qml` 测公开 QML 组件的行为契约（按 Qool 模块分 QML 测试批次）。

## 运行（三条通道，同一批标准 Qt Test exe）

通道命令表（单一事实源）见 `AGENTS.md`「运行通道」——`cmake --build build/build-<kit>-<Type> --target run-tests`（聚合）/ `ctest --preset dev-<kit>-<type>`（CTest）/ `build/build-<kit>-<Type>/QoolUITests/<层>/tst_*.exe -txt`（直接运行）。本手册只补充操作性语法：

- **ctest 筛选**：单个 `ctest -R tst_qool_vector2d`；按前缀 `ctest -R "tst_qool_"`（core 层 4 个 + qml harness）；注意 CTest 正则**不支持 `|` 交替**，多组筛选分开跑或只保留共同前缀
- **失败重跑**：`ctest --rerun-failed`
- **CI 报告**：`ctest --output-junit result.xml`（配合 `--output-on-failure`）
- **QML 无头**：QML 测试已内置 `-platform offscreen`（测试注册机制保证，见 AGENTS.md「CMake 组织」），无需手动加

> 测试 exe 输出在 `build/build-<kit>-<Type>/QoolUITests/{common,core,qml}` 三层；测试 target 在默认构建（all）中——`cmake --build build/build-<kit>-<Type>` 即构建测试（落地修正：EXCLUDE_FROM_ALL 导致 QtCreator 面板运行前构建不含测试、exe 缺失全红，已移除）。

> **QML 测试与 Qt Creator 的 QuickTest 集成不兼容（重要）**：本设施 QML harness 共享同一个 `qml_test_main.cpp`（各批次经编译宏 `-D QUICK_TEST_SOURCE_DIR=...` 注入批次目录），Qt Creator 的 QuickTest 扫描器无法从该 cpp 推断「exe ↔ QML 目录」对应关系（同一 cpp 被多个 target 编译 → 关联歧义）。表现为：Tests 面板只能发现默认目录（`tst_qool_qml/`）的 QML 测试，且运行 QML 测试时弹出「选择 executable」、列出全部 EXECUTABLE；其余批次的 QML 测试根本不被发现。**QML 测试一律通过 CTest 运行**（`ctest --preset dev-<kit>-<type>`，或筛选 `ctest -R "tst_.*_qml"` / `--rerun-failed`），不要依赖 Qt Creator 面板的 QuickTest 运行按钮。

### Windows 一键（环境+配置+构建+测试）

```bash
python Scripts/qoolui_build_windows.py configure --qt C:/Qt/6.11.1   # 首次必带 --qt（脚本内置 vcvars/MinGW 环境准备）
python Scripts/qoolui_build_windows.py build
python Scripts/qoolui_build_windows.py test                          # ctest 聚合，输出落盘 build/build-<kit>-<Type>/test.log
```

MinGW 工具链加 `--kit gcc`。`run`（启动 QoolUIExample）同需 `--qt`（或环境 `QT_DIR`）——开发模式 Qt 运行时注入依赖它，缺失时 exe 启动即退出。一键操作流程的唯一事实源在本手册（AGENTS.md 仅一行引用）。

### 规模化（上百个 tst 时）

- **注册全自动**：`common/` 用 `file(GLOB CONFIGURE_DEPENDS tst_*.cpp)` 自动发现——新增测试文件零配置进入构建/CTest/run-tests（Ninja 检测到新文件自动重新配置）；`qml/` 由 harness 递归扫描 `tst_*.qml`，同样零配置。**只有 `core/` 保持显式注册**（每个测试需显式声明被测源，无法自动推断，这是刻意的）——机制定案见 `AGENTS.md`「CMake 组织」
- **run-tests 注册表驱动**：COMMAND 从 `QOOLUI_TEST_TARGETS` 自动生成（`qoolui_add_cpp_test` 注册即纳入）；测试特定参数（如 QML 的 `-platform offscreen`）经 `QOOLUI_TEST_ARGS_<target>` 变量声明。**新增测试无需改任何列表**
- **CTest 是规模化主通道**（Qt 官方跑上百测试的方式）：
  - 并行：`ctest --preset dev-<kit>-<type> -j8`
  - 筛选/重跑/CI 报告见上文操作性语法
- **run-tests 保持串行失败即停**是有意的：开发时快速定位第一个失败；规模化/并行/全量报告走 ctest

## 如何新增测试

### C++ 测试（QoolCommon / Qool 核心类型）

1. 在对应子目录建 `tst_<对象>.cpp`，类名 `Test<对象>`；测试用例用宏族 `QOOL_TEST_CASE(test_xxx)` 类体内内联定义（`#include "qool_test.hpp"`，宏族约束见 AGENTS.md）；结尾 `QTEST_MAIN(TestXxx)` + `#include "tst_xxx.moc"`（AUTOMOC 自动处理；不用 `QT_MOC`——CMake AUTOMOC 不支持，实测）
2. 注册（按层区分）：
   - **QoolCommon（common/）**：**零配置**——`file(GLOB CONFIGURE_DEPENDS)` 自动发现，新文件放进目录即进入构建/CTest/run-tests，**不要手动写 `qoolui_add_cpp_test`**（会与 GLOB 重复生成同名 target 导致构建失败）
   - **Qool 核心类型（core/）**：在 `core/CMakeLists.txt` 显式注册 `qoolui_add_cpp_test(tst_qool_<对象> tst_<对象>.cpp <被测源 .cpp>)` + `target_link_libraries(... PRIVATE Qool QoolCommon QoolUITestSupport Qt6::Quick)`——**不要链接 Qool target 取实现**（Qool 是 DLL 且按仓库原则不导出 C++ 符号），把被测 `.cpp` 直接编入测试 target 仅取头文件路径。**必须补 PRIVATE include：`target_include_directories(tst_qool_<对象> PRIVATE ${QOOL_SRC_PRIVATE_INCLUDES})`**——被测头内部可能引用 Qool 模块的 PRIVATE include 目录下的头（实例：`gadgets/*.h` → `"qool_shapecontrol_gadget.h"`（shapecontrol/）、`"qool_smartobj.h"`（utils/）、`"qool_literals.h"`（qore/）），这些目录不随 Qool target 传播，漏一层断一层（C1083 逐个暴露）。清单在 `core/CMakeLists.txt` 顶部定义，与 `Qool/CMakeLists.txt` 的 PRIVATE include 同步维护。见 `core/CMakeLists.txt` 的链接策略说明
3. 测试风格约定：
   - 数据驱动：`_data()` + `QFETCH`（见 tst_math.cpp）
   - 浮点断言：自备 `fuzzy_eq`（QCOMPARE 浮点是精确比较）
   - 属性/信号契约：`QSignalSpy` + 相等守卫断言（同值赋值不发信号）
   - 基准：`QBENCHMARK`（tst_math.cpp 有示范）
   - 纯逻辑用 QCoreApplication（QTEST_MAIN 自动选择）；只有真正需要窗口的测试才碰 QPA

### QML 测试（按 Qool 模块分 QML 测试批次）

1. 在对应模块的**批次目录**（如 `qml/tst_qool_qml/`）下建 `tst_<组件>.qml`：`import QtQuick; import QtTest; import Qool` + `TestCase { name: ... }`
2. harness（共享模板 `qml_test_main.cpp`）递归扫描批次目录下所有 `tst_*.qml`；Qool 模块 import path 已注入（`QOOLUI_TEST_QML_IMPORT_PATH` → `build/build-<kit>-<Type>/qml`）
3. 测试资源放批次目录 `assets/` 子目录（文件系统相对路径访问）；**`assets/` 内不得有 `tst_` 前缀文件**（递归扫描误判）
4. **状态隔离是硬要求**：TestCase 的各测试函数**共享同一实例**且按函数名顺序执行——共享状态会跨测试泄漏（曾踩：interval 被前一个测试改写导致后一个断言失败）。每个测试函数用 `createTemporaryObject(component, root)` 创建独立实例 + 动态创建 SignalSpy（见 tst_timerlatch.qml 的 `makeLatch`/`makeSpy`）
5. 时序断言用 `tryCompare(obj, prop, value, timeout)`（内部跑事件循环，Timer 驱动可测）
6. `import Qool` 走运行时解析：QML 测试文件**不参与 qmlcachegen AOT**，无需改模块 CMake
7. **窗口访问**：TestCase **没有 `window` 属性**（取到 undefined）；正确途径是 `Window.window` 附加属性（`import QtQuick.Window`）。`QQuickWindow::itemAt` **非 Q_INVOKABLE**，QML 无法调用——引擎 hit-test（点击穿透/掩码命中）的端到端验证不可行；掩码/命中类契约改为直接调用掩码对象的 `contains()`（Q_INVOKABLE）断言（见 tst_crystal.qml 的 `expectContains` 辅助）
8. **新增整个测试批次**（新模块的 `tst_<模块>_qml` harness target）：机制与步骤见 `AGENTS.md`「QML 测试批次组织」

## Windows 环境经验（msvc/mingw 通用，供其它平台对照）

> 这些是 Windows 特有的坑与解法（msvc/mingw 双工具链均适用）；Linux/macOS 系统 Qt 无此问题（下述逻辑均已包在 `if(WIN32)` 内，其它平台零污染）。

1. **Qt DLL 部署**：测试 exe 依赖 Qt DLL，不能依赖 PATH（cmd 里没有）。POST_BUILD 用 `$<TARGET_RUNTIME_DLLS>` + `cmake -E copy_if_different` 把依赖 DLL 复制到 exe 目录 → exe 独立可运行。
2. **DLL 部署的副作用——Qt 前缀推导失效**：Qt 以 Qt6Core.dll 的位置推导「安装前缀」。DLL 复制到 exe 目录后，平台插件（`plugins/platforms`）与 Qt QML 模块（`qml/`）都找不到了。解法：**qt.conf 自包含方案**——core/qml 层 configure 期生成 `qt.conf` 到 exe 旁（`[Paths] Prefix=<Qt 安装前缀>`，绝对路径正斜杠），QLibraryInfo 读取并覆盖推导，任何运行通道（QtCreator 面板/run-tests/ctest/直跑）无需环境注入。common 层纯 QCoreApplication 不需要。改模板后需重新 configure。
3. **CTest 的 ENVIRONMENT 陷阱**：`ENVIRONMENT` 属性的 PATH 值在 Windows 按 `;` 拆分，多路径注入会损坏（测试报 0xc0000135 DLL 找不到）。**不要用 ENVIRONMENT 设 PATH**；本设施零环境注入（qt.conf），天然规避。
4. **MSYS/Git-Bash 管道伪象（重大）**：从 MSYS bash 管道运行 Qt Test 程序时，**stdout logger 输出完全丢失**且退出码不可信（表现为「无声退出 0」或虚假的 0xC0000409 崩溃）。测试本体正常执行。**判定测试结果必须从真实 Windows 控制台（cmd/Windows Terminal/PTY）运行**。这是观测通道问题，不是测试或 Qt 的问题。
5. **bat 脚本的雷**（如果写 Windows 脚本，优先 pwsh）：`for /f in (...)` 内路径含 `(x86)` 破坏括号块；调 bat 必须 `call` 否则控制权不返回；UTF-8 注释在默认代码页解析出错；必须 CRLF 行尾。全部踩过，pwsh 无此问题。
6. **Ninja 并行 POST_BUILD 竞争**：多个测试 target 的 POST_BUILD 并发复制同一目录（如 plugins/platforms）可能 Permission denied——重跑增量构建即可（本设施已消除该复制，仅当新增同类复制时注意）。
7. **AUTOGEN 状态残留（C1083 排查）**：测试 target 的源文件列表经历过「空 → 有」的 configure（如中间版本配置错误导致 add_executable 无源）后，autogen timestamp 可能残留为最新（比源文件新）→ 后续正确 configure 不重置 autogen → 构建跳过 moc 生成 → `fatal error C1083: "tst_xxx.moc": No such file or directory`（build.make 中该 target 无 moc 规则可佐证）。**修复：删除构建目录中对应测试目录（如 `build/build-<kit>-<Type>/QoolUITests`）强制重新 configure**——仅重跑 cmake 不重置（实测）。
8. **Qt 前缀定位**：`${Qt6_DIR}/../../..` = Qt 安装前缀（Qt6_DIR = `<前缀>/lib/cmake/Qt6`）。
9. **QML 插件依赖的 Qt DLL（新增模块测试必查）**：`$<TARGET_RUNTIME_DLLS>` 只覆盖**链接依赖**——QML 引擎运行时加载的插件（如 `QtQuick.Shapes` 的 qmlshapesplugin）依赖的 Qt DLL（如 `Qt6QuickShapesd.dll`）不在任何 target 的 RUNTIME_DLLS 里，测试首次 import 该模块时插件加载失败（`Cannot load library ... qmlshapesplugind.dll`）。**解法**：`find_file` 按构建类型定位 DLL（`Qt6QuickShapes$<$<CONFIG:Debug>:d>.dll` 需分开 find） + 条件 POST_BUILD 复制（见 `qml/CMakeLists.txt` 的 QuickShapes 段，模板可直接复制）。任何新用到的 QML 插件模块都要检查一遍。

## 平台差异（其它平台怎么跑）

- Linux/macOS：系统 Qt 在标准路径，**无需** DLL 部署/插件注入/`QT_PLUGIN_PATH`——`if(WIN32)` 之外零逻辑，configure/build/test 用对应 kit 的 preset（如 `dev-gcc-debug`，kit 按工具链选，矩阵见根 AGENTS.md「构建命令」）；骨架脚本说明以根 AGENTS.md 为准，本手册不重复
- CI 无头：QML 测试已内置 `-platform offscreen`（测试注册机制保证）；Linux CI 若需可再加 `QT_QPA_PLATFORM=offscreen`

## 测试设施的价值记录

设施建成以来逮住的缺陷分两类，守护情况如实标注：

### 测试逮住的产品缺陷（均有回归测试守护）

|缺陷|位置|机制|
|---|---|---|
|Vector2D 拷贝构造笔误|`Qool/datatypes/qool_vector2d.cpp`|`m_vector{other.m_from}`——拷贝后向量被起点取代（与拷贝赋值不一致）；QML 值类型按值传递直接受害|
|NumberRanger::format 字符串分支不可达|`Qool/utils/qool_numberranger.cpp`|QString 恒 `canConvert<qreal>`，数值分支先命中，正则替换逻辑成死代码——「字符串内数字按精度替换」承诺从未生效|
|format 字符串分支 'g' 精度语义错误|同上|`'g', decimals` 的精度是**有效数字**而非小数位，1.23 被截成 "1.2"|
|Polar2D 乘除语义|`Qool/datatypes/qool_polar2d.cpp`|极坐标乘除的语义缺陷（幅角/模长处理），QML 值类型运算直接受害|
|PositionLocker 动态跟随|`Qool/Qool/PositionLocker.qml`|目标/偏移变化时锁定位置未随动，声明式绑定断链|

### 设施自身修复（构建配置缺陷，无测试守护）

|缺陷|位置|机制|
|---|---|---|
|QML 测试 DLL 副本同步|`QoolUITests/CMakeLists.txt`|qml 层复制的 Qool 相关 DLL 未声明依赖关系，Qool 重建后副本陈旧——`LINK_DEPENDS` 声明文件依赖（构建配置修复，测试逮不住）|

另外 QML 测试暴露测试设计陷阱（共享实例状态泄漏）→ 已用 `createTemporaryObject` 隔离，记录于上。

## 常用调试技巧

- 单个函数：`build/build-<kit>-<Type>/QoolUITests/common/tst_math.exe cycle_in_range`（函数名参数）
- 数据子集：`... cycle_in_range:wrap_above`（`:数据行`）
- 函数清单：`-functions`；详细输出：`-v1`/`-v2`
- 显式日志格式：`-o -,txt`（或 `-txt`）
- 目视渲染 QML 测试：`build/build-<kit>-<Type>/QoolUITests/qml/tst_qool_qml.exe`（不带 `-platform offscreen`）
