# QoolUI 测试设施

Qt Test + Qt Quick Test 双栈程序化测试设施。本文件是**使用手册**（如何写/跑测试）与**平台经验记录**（Windows/MSVC 的坑与解法，供其它平台对照）。

## 架构

```
QoolUI/tests/
├── CMakeLists.txt          # 总入口：公共函数、环境策略、run-tests 聚合 target
├── common/                 # QoolCommon 纯 C++ 模板库（Qt Test，QCoreApplication）
│   ├── CMakeLists.txt
│   └── tst_math.cpp        # math 全套：数据驱动 + 边界 + QBENCHMARK 示范
├── core/                   # Qool 核心 C++ 类型（Qt Test，直接编译被测 .cpp）
│   ├── CMakeLists.txt
│   ├── tst_vector2d.cpp    # 值类型：构造/运算符/转换/属性契约
│   └── tst_numberranger.cpp# 属性宏体系：默认值/守卫信号/校验逻辑/Q_PROPERTY 契约
└── qml/                    # QML 行为测试（Qt Quick Test harness）
    ├── CMakeLists.txt
    ├── tst_qml_main.cpp    # QUICK_TEST_MAIN_WITH_SETUP（注入 Qool 模块 import path）
    └── tst_timerlatch.qml  # 组件行为：声明式状态/信号/时序（createTemporaryObject 隔离）
```

**分层与被测面一一对应**：`common` 测脱离 Qool 的纯逻辑（QCoreApplication 即可），`core` 测 Qool 的 C++ 类型，`qml` 测公开 QML 组件的行为契约。

## 运行（三条通道，同一批标准 Qt Test exe）

|通道|命令|适用|
|---|---|---|
|聚合 target（日常）|`cmake --build build --target run-tests`|一条命令跑全部、失败即红，无 CTest 机制|
|CTest|`ctest --preset dev`（或 `ctest -R tst_`）|CI/筛选/并行/报告|
|直接运行|`build/tst_qoolcommon_math.exe -txt`|单个测试调试；QML 加 `-platform offscreen` 无头|

Windows 一键（配置+构建+测试）：`pwsh -File scripts/win_build_test.ps1`（仅本机脚本，见「平台差异」）。

## 如何新增测试

### C++ 测试（QoolCommon / Qool 核心类型）

1. 在对应子目录建 `tst_<对象>.cpp`，类名 `Test<对象>`，测试槽 `void test_xxx()`；结尾 `QTEST_MAIN(TestXxx)` + `#include "tst_xxx.moc"`（AUTOMOC 自动处理）
2. 子目录 `CMakeLists.txt` 注册：
   - QoolCommon：`qoolui_add_cpp_test(tst_xxx tst_xxx.cpp)` + `target_link_libraries(tst_xxx PRIVATE QoolCommon)`
   - Qool 核心类型：**不要链接 Qool target**（Qool 是 DLL 且按仓库原则不导出 C++ 符号）——把被测 `.cpp` 直接编入测试 target，链接 `Qool QoolCommon Qt6::Quick` 仅取头文件路径。见 `core/CMakeLists.txt` 的链接策略说明
3. 测试风格约定：
   - 数据驱动：`_data()` + `QFETCH`（见 tst_math.cpp）
   - 浮点断言：自备 `fuzzy_eq`（QCOMPARE 浮点是精确比较）
   - 属性/信号契约：`QSignalSpy` + 相等守卫断言（同值赋值不发信号）
   - 基准：`QBENCHMARK`（tst_math.cpp 有示范）
   - 纯逻辑用 QCoreApplication（QTEST_MAIN 自动选择）；只有真正需要窗口的测试才碰 QPA

### QML 测试

1. 在 `qml/` 下建 `tst_<组件>.qml`：`import QtQuick; import QtTest; import Qool` + `TestCase { name: ... }`
2. harness（tst_qml_main.cpp）自动扫描 `qml/` 目录下所有 `tst_*.qml`，无需改 CMake；Qool 模块 import path 已注入
3. **状态隔离是硬要求**：TestCase 的各测试函数**共享同一实例**且按函数名顺序执行——共享状态会跨测试泄漏（曾踩：interval 被前一个测试改写导致后一个断言失败）。每个测试函数用 `createTemporaryObject(component, root)` 创建独立实例 + 动态创建 SignalSpy（见 tst_timerlatch.qml 的 `makeLatch`/`makeSpy`）
4. 时序断言用 `tryCompare(obj, prop, value, timeout)`（内部跑事件循环，Timer 驱动可测）
5. `import Qool` 走运行时解析：QML 测试文件**不参与 qmlcachegen AOT**，无需改模块 CMake

## Windows/MSVC 环境经验（本设施踩过的坑与解法）

> 这些是 Windows + MSVC + Qt msvc 套件特有的；Linux/macOS 系统 Qt 无此问题（下述逻辑均已包在 `if(WIN32)` 内，其它平台零污染）。

1. **Qt DLL 部署**：测试 exe 依赖 Qt DLL，不能依赖 PATH（cmd 里没有）。POST_BUILD 用 `$<TARGET_RUNTIME_DLLS>` + `cmake -E copy_if_different` 把依赖 DLL 复制到 exe 目录 → exe 独立可运行。
2. **DLL 部署的副作用——Qt 前缀推导失效**：Qt 以 Qt6Core.dll 的位置推导「安装前缀」。DLL 复制到 exe 目录后，平台插件（`plugins/platforms`）与 Qt QML 模块（`qml/`）都找不到了。解法：POST_BUILD 复制 `platforms` 插件目录到 exe 旁 + 运行通道注入 `QT_PLUGIN_PATH=<Qt前缀>/plugins`、`QML_IMPORT_PATH=<Qt前缀>/qml`（后者仅 QML 测试需要）。
3. **CTest 的 ENVIRONMENT 陷阱**：`ENVIRONMENT` 属性的 PATH 值在 Windows 按 `;` 拆分，多路径注入会损坏（测试报 0xc0000135 DLL 找不到）。**不要用 ENVIRONMENT 设 PATH**；要么如本设施用 `cmake -E env`（run-tests）/ `ENVIRONMENT_MODIFICATION`（ctest，CMake 3.22+，平台自适应分隔符）。
4. **MSYS/Git-Bash 管道伪象（重大）**：从 MSYS bash 管道运行 Qt Test 程序时，**stdout logger 输出完全丢失**且退出码不可信（表现为「无声退出 0」或虚假的 0xC0000409 崩溃）。测试本体正常执行。**判定测试结果必须从真实 Windows 控制台（cmd/Windows Terminal/PTY）运行**。这是观测通道问题，不是测试或 Qt 的问题。
5. **bat 脚本的雷**（如果写 Windows 脚本，优先 pwsh）：`for /f in (...)` 内路径含 `(x86)` 破坏括号块；调 bat 必须 `call` 否则控制权不返回；UTF-8 注释在默认代码页解析出错；必须 CRLF 行尾。全部踩过，pwsh 无此问题。
6. **Qt 前缀定位**：`${Qt6_DIR}/../../..` = Qt 安装前缀（Qt6_DIR = `<前缀>/lib/cmake/Qt6`）。

## 平台差异（其它平台怎么跑）

- Linux/macOS：系统 Qt 在标准路径，**无需** DLL 部署/插件注入/`QT_PLUGIN_PATH`——`if(WIN32)` 之外零逻辑，直接 `cmake --preset dev && cmake --build --preset dev --target run-tests` 即可
- CI 无头：QML 测试已内置 `-platform offscreen`（add_test 参数）；Linux CI 若需可再加 `QT_QPA_PLATFORM=offscreen`
- `scripts/win_build_test.ps1` 是 Windows/MSVC 本机脚本（vswhere 定位 VS + vcvars + qt-cmake + run-tests），其它平台不要用它

## 测试设施的价值记录

设施建成即逮住并修复 3 个真实缺陷（均有回归测试守护）：

|缺陷|位置|机制|
|---|---|---|
|Vector2D 拷贝构造笔误|`Qool/datatypes/qool_vector2d.cpp`|`m_vector{other.m_from}`——拷贝后向量被起点取代（与拷贝赋值不一致）；QML 值类型按值传递直接受害|
|NumberRanger::format 字符串分支不可达|`Qool/utils/qool_numberranger.cpp`|QString 恒 `canConvert<qreal>`，数值分支先命中，正则替换逻辑成死代码——「字符串内数字按精度替换」承诺从未生效|
|format 字符串分支 'g' 精度语义错误|同上|`'g', decimals` 的精度是**有效数字**而非小数位，1.23 被截成 "1.2"|

另外 QML 测试暴露测试设计陷阱（共享实例状态泄漏）→ 已用 `createTemporaryObject` 隔离，记录于上。

## 常用调试技巧

- 单个函数：`tst_qoolcommon_math.exe cycle_in_range`（函数名参数）
- 数据子集：`tst_qoolcommon_math.exe cycle_in_range:wrap_above`（`:数据行`）
- 函数清单：`-functions`；详细输出：`-v1`/`-v2`
- 显式日志格式：`-o -,txt`（或 `-txt`）
- 目视渲染 QML 测试：`build/tst_qool_qml.exe`（不带 `-platform offscreen`）
