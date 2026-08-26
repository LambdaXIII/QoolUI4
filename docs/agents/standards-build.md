## 构建命令与设施

**规范入口是 `Scripts/qoolui_build_*.py` 工具脚本**（Windows/Linux 当前可用；macOS 为骨架，落地时完善）。脚本职责：工具链环境准备（MSVC 经 vswhere→vcvars64 注入、Windows MinGW/Clang 经 PATH 前置 Qt 工具链、Linux GCC/Clang 经 CC/CXX 注入）+ 命令实现（configure/build/test/run/install/deploy/release）。约定内置（preset 映射、目录命名、deploy=install+zip 归档），个性化参数输入（--qt/--jobs/--prefix/--version/透传）。

```bash
# Windows/MSVC（默认 kit=msvc, type=debug——开发期默认，xDebug 输出可见）
python Scripts/qoolui_build_windows.py configure --qt <Qt安装根>
python Scripts/qoolui_build_windows.py build --jobs 8
python Scripts/qoolui_build_windows.py test          # ctest 聚合，输出落盘 build/build-<kit>-<Type>/test.log
python Scripts/qoolui_build_windows.py run           # 启动 QoolUIExample（需 --qt 或环境 QT_DIR——开发模式 Qt 运行时注入依赖它）
python Scripts/qoolui_build_windows.py install       # 输出到 build/build-<kit>-<Type>/install（含 Qt 部署脚本收集的依赖）
python Scripts/qoolui_build_windows.py deploy        # install + zip 归档
# MinGW：--kit gcc；Clang：--kit clang（Qt 安装根自动按 kit 选工具链目录）

# Linux/GCC（默认 kit=gcc, type=debug；--qt 可省略，自动探测 qmake6 或 /usr）
python Scripts/qoolui_build_linux.py configure --qt /usr
python Scripts/qoolui_build_linux.py build --jobs 8
python Scripts/qoolui_build_linux.py test           # ctest 聚合，输出落盘 build/build-<kit>-<Type>/test.log
QT_QPA_PLATFORM=offscreen python Scripts/qoolui_build_linux.py run
python Scripts/qoolui_build_linux.py install        # 输出到 build/build-<kit>-<Type>/install
python Scripts/qoolui_build_linux.py deploy         # install + zip 归档
# Clang：--kit clang（构建目录按 kit 隔离为 build/build-clang-<Type>）
```

### 配置文件

**kit×type 矩阵**（CMakePresets.json）：`dev-<kit>-<type>` preset 对应用户目录 `build/build-<kit>-<Type>`（如 `dev-msvc-debug` → `build/build-msvc-Debug`）。kit = 编译方式（msvc/clang/gcc），type = debug/release（默认 debug）。编译器由脚本环境准备决定，preset 不指定——构建目录按 kit 隔离保证工具链不混。CMake 原生通道（无脚本环境准备时）亦可直接 `cmake --preset dev-msvc-debug`。



### 构建通道经验
- **判读测试输出走 eval 内核 python `subprocess` + 文件重定向**，勿在 MSYS bash 里直接跑 exe 判读（stdout 被吞、退出码不可信、Windows 盘符路径被解析成函数名）——这是元问题，别把观测通道问题误诊成测试缺陷。
- Qt Creator 产物的 File API reply（`build/<kit>-<Type>/.cmake/api/v1/reply/`）是 CMake 结构的权威来源：codemodel 主文件（`codemodel-v2-*.json`）的 `targets[]` 是**索引**，每个 target 的 `directory`/`paths.source`/compileGroups 等细节在各自 `target-<name>-<Type>-*.json` 里（`paths` 字段）+ `directories[]` 按 `directoryIndex` 索引——排查 target 归属（如「哪些 target 共享目录」）读这两处。
