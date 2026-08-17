#!/usr/bin/env python3
"""QoolUI 构建工具：共享逻辑。

平台入口脚本（qoolui_build_windows.py / _macos.py / _linux.py）负责环境
准备（工具链定位/注入），本模块承载全部命令实现：

  configure/build/test/run/install/deploy/release

约定内置（不随环境变化）：
  - kit×type preset 映射：dev-<kit>-<type>（CMakePresets.json）
  - 构建目录：build/build-<kit>-<Type>
  - deploy = install + zip 归档；release = deploy + 版本归档名

QML 测试无头（offscreen）由测试注册机制保证（add_test 参数 +
QOOLUI_TEST_ARGS_<target>，见 QoolUITests/AGENTS.md），本模块的
test 命令仅是 ctest 聚合通道，不承担 offscreen 注入。

个性化参数（--qt/--cmake-args/--jobs/--prefix）由命令行输入。

仅标准库依赖（argparse/subprocess/zipfile）。本模块不可直接运行——
由平台入口脚本 import 后 dispatch。
"""

import argparse
import os
import shutil
import subprocess
import sys
import zipfile
from pathlib import Path

KITS = ("msvc", "clang", "gcc")
TYPES = ("debug", "release")
COMMANDS = ("configure", "build", "test", "run", "install", "deploy", "release")
DEFAULT_VERSION = "4.0.0"

REPO = Path(__file__).resolve().parent.parent

# Qt 官方安装器按工具链分目录的惯例子目录（kit → 候选子目录）
QT_KIT_SUBDIRS = {
    "msvc": ("msvc2022_64",),
    "gcc": ("mingw_64",),
    "clang": ("mingw_64",),
}


def qt_kit_dir(qt_dir: str, kit: str) -> str:
    """把 --qt 参数归一化为具体工具链目录。

    --qt 可能传 Qt 安装根（C:\\Qt\\6.11.1）或具体工具链目录
    （C:\\Qt\\6.11.1\\msvc2022_64）。后者直接用；前者按 kit 惯例
    子目录补全（Qt 官方安装器布局）。找不到时原样返回（报错留给
    cmake 的 find_package）。
    """
    if not qt_dir:
        return qt_dir
    p = Path(qt_dir)
    if (p / "lib" / "cmake" / "Qt6").exists():
        return qt_dir
    for sub in QT_KIT_SUBDIRS.get(kit, ()):
        if (p / sub / "lib" / "cmake" / "Qt6").exists():
            return str(p / sub)
    return qt_dir


def preset_name(kit: str, type_: str) -> str:
    return f"dev-{kit}-{type_}"


def build_dir(kit: str, type_: str) -> Path:
    return REPO / "build" / f"build-{kit}-{type_.capitalize()}"


def run_cmd(cmd, cwd=None, env=None, log_path=None, check=True):
    """运行命令：终端实时输出 + 可选落盘（双写）。

    env 为 None 时继承当前环境；平台入口注入的工具链环境经 env 传入。
    """
    if log_path:
        log_path.parent.mkdir(parents=True, exist_ok=True)
    log = open(log_path, "w", encoding="utf-8") if log_path else None
    print(f">>> {' '.join(cmd) if isinstance(cmd, list) else cmd}", flush=True)
    try:
        proc = subprocess.Popen(
            cmd, cwd=str(cwd) if cwd else None, env=env,
            stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True,
            encoding="utf-8", errors="replace",
        )
        for line in proc.stdout:
            print(line, end="", flush=True)
            if log:
                log.write(line)
        # stdout EOF 不等于进程退出（子进程可能持有句柄）；必须 wait
        # 后才能读 returncode——否则读到 None，sys.exit(None) 静默变 0
        proc.wait()
    finally:
        if log:
            log.close()
    if check and proc.returncode != 0:
        sys.exit(proc.returncode)
    return proc.returncode


# ---- 命令实现 -----------------------------------------------------------

def configure(kit: str, type_: str, qt_dir: str, extra: list, env=None):
    env = dict(env or os.environ)
    if qt_dir:
        env["QT_DIR"] = qt_dir
    elif "QT_DIR" not in env:
        print("警告: QT_DIR 未设置且未传 --qt，preset 的 CMAKE_PREFIX_PATH 将为空",
              file=sys.stderr)
    run_cmd(["cmake", "--preset", preset_name(kit, type_), *extra], env=env,
            log_path=build_dir(kit, type_) / "configure.log")


def build(kit: str, type_: str, jobs: int, extra: list, env=None):
    cmd = ["cmake", "--build", str(build_dir(kit, type_))]
    if jobs:
        cmd += ["-j", str(jobs)]
    cmd += extra
    run_cmd(cmd, env=env, log_path=build_dir(kit, type_) / "build.log")


def test(kit: str, type_: str, extra: list, env=None):
    run_cmd(["ctest", "--preset", preset_name(kit, type_), *extra], env=env,
            log_path=build_dir(kit, type_) / "test.log")


def _find_example_exe(kit: str, type_: str) -> Path:
    root = build_dir(kit, type_)
    for p in sorted(root.rglob("appQoolUIExample.exe")):
        return p
    raise SystemExit(f"找不到 QoolUIExample 可执行文件（{root}），请先 build")


def run_app(kit: str, type_: str, args: list, env=None):
    exe = _find_example_exe(kit, type_)
    env = dict(env or os.environ)
    # 开发模式运行依赖：Qt 运行时不在构建目录（QtCreator 从 Qt 前缀注入，
    # 脚本需自行补）——DLL/插件/Qt 自带 QML 模块路径
    qt_dir = env.get("QT_DIR")
    if qt_dir:
        bin_dir = Path(qt_dir) / "bin"
        env["PATH"] = str(bin_dir) + os.pathsep + env.get("PATH", "")
        env.setdefault("QT_PLUGIN_PATH", str(Path(qt_dir) / "plugins"))
        qml_paths = [str(Path(qt_dir) / "qml"),
                     str(build_dir(kit, type_) / "qml")]  # Qool 模块在构建目录
        env["QML_IMPORT_PATH"] = os.pathsep.join(
            [p for p in qml_paths if Path(p).exists()])
    print(f">>> {exe} {' '.join(args)}", flush=True)
    return subprocess.call([str(exe), *args], env=env)


def install(kit: str, type_: str, prefix: str, extra: list, env=None):
    """安装当前唯一消费方——QoolUIExample 应用。

    概念边界（勿忘）：本通道部署的是【QoolUIExample 的产物】。经
    qt_generate_deploy_qml_app_script（windeployqt）收集的 QML 模块、
    Qt 运行时、翻译均为 exampleapp 的运行依赖，不是 QoolUI 库本体被
    安装。QoolUI 库的交付包（按模块可删减的 qml 目录 + Includes/interfaces
    头文件 + Markdown 文档包）是另一条待设计通道——打包方案定案前，
    不要误用本通道产物当库交付基础。
    """
    prefix = prefix or str(build_dir(kit, type_) / "install")
    run_cmd(["cmake", "--install", str(build_dir(kit, type_)),
             "--prefix", prefix, *extra], env=env)


def _zipdir(src: Path, zf: zipfile.ZipFile, arc_prefix: str):
    for p in sorted(src.rglob("*")):
        if p.is_file():
            zf.write(p, f"{arc_prefix}/{p.relative_to(src).as_posix()}")


def deploy(kit: str, type_: str, prefix: str, version: str, env=None):
    """QoolUIExample 应用安装包归档（install 产物整体 zip）。

    同 install 的概念边界：归档的是 exampleapp 的完整可分发安装包
    （含其依赖的 QoolUI 模块与 Qt 运行时），不是 QoolUI 库交付包。
    """
    prefix = prefix or str(build_dir(kit, type_) / "install")
    install(kit, type_, prefix, [], env=env)
    arc = build_dir(kit, type_) / f"qoolui-{version}-{kit}-{type_}.zip"
    print(f">>> 归档: {arc}", flush=True)
    with zipfile.ZipFile(arc, "w", zipfile.ZIP_DEFLATED) as zf:
        _zipdir(Path(prefix), zf, "qoolui")
    print(f"完成: {arc}", flush=True)


def release(kit: str, type_: str, prefix: str, version: str, env=None):
    deploy(kit, type_, prefix, version, env=env)


# ---- 调度 ---------------------------------------------------------------

def dispatch(command: str, kit: str, type_: str, env=None, **kw):
    if command == "configure":
        configure(kit, type_, kw.get("qt_dir"), kw.get("extra") or [], env=env)
    elif command == "build":
        build(kit, type_, kw.get("jobs", 0), kw.get("extra") or [], env=env)
    elif command == "test":
        test(kit, type_, kw.get("extra") or [], env=env)
    elif command == "run":
        return run_app(kit, type_, kw.get("extra") or [], env=env)
    elif command == "install":
        install(kit, type_, kw.get("prefix"), kw.get("extra") or [], env=env)
    elif command == "deploy":
        deploy(kit, type_, kw.get("prefix"), kw.get("version", DEFAULT_VERSION),
               env=env)
    elif command == "release":
        release(kit, type_, kw.get("prefix"), kw.get("version", DEFAULT_VERSION),
                env=env)
    return 0
