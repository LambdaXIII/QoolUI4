#!/usr/bin/env python3
"""QoolUI 构建工具：Linux 入口。

按编译方式（kit）准备工具链环境后委托 qoolui_build_common：
  gcc   — GNU GCC：要求 PATH 中有 gcc/g++；设置 CC/CXX 后注入
  clang — Clang：要求 PATH 中有 clang/clang++；设置 CC/CXX 后注入

用法:
  python qoolui_build_linux.py <command> [--kit gcc|clang]
      [--type debug|release] [--qt <Qt 路径>] [--jobs N]
      [--prefix <install 前缀>] [--version <归档版本>] [-- <cmake 额外参数>]

命令: configure | build | test | run | install | deploy | release
默认: kit=gcc, type=debug（开发期默认 Debug——xDebug 输出可见）。

Qt 路径解析：
  --qt 支持 Qt 版本根（如 ~/Qt/6.11.1）或具体工具链目录
  （如 ~/Qt/6.11.1/gcc_64）；缺省时依次使用 $QT_DIR、
  qmake6 -query QT_INSTALL_PREFIX、/usr。
"""

import argparse
import os
import shutil
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import qoolui_build_common as common

LINUX_KITS = ("gcc", "clang")


def _require(prog: str, hint: str = "") -> str:
    path = shutil.which(prog)
    if not path:
        raise SystemExit(f"{prog} 未找到（PATH 中不存在）。{hint}".strip())
    return path


def _check_tools(kit: str):
    """检查 Linux 构建必需工具：cmake/ninja/编译器。"""
    _require("cmake", "请安装 CMake 3.30+。")
    _require("ninja", "请安装 Ninja（CMakePresets 使用 Ninja 生成器）。")
    compilers = ("gcc", "g++") if kit == "gcc" else ("clang", "clang++")
    for prog in compilers:
        _require(prog, "请安装对应的编译器。")


def _make_env(kit: str) -> dict:
    """复制当前环境，并按 kit 注入 CC/CXX 绝对路径。"""
    env = os.environ.copy()
    if kit == "gcc":
        env["CC"] = shutil.which("gcc")
        env["CXX"] = shutil.which("g++")
    else:
        env["CC"] = shutil.which("clang")
        env["CXX"] = shutil.which("clang++")
    return env


def _default_qt_dir() -> str:
    """自动探测 Qt 前缀：qmake6/qmake → /usr。"""
    qmake = shutil.which("qmake6") or shutil.which("qmake")
    if qmake:
        try:
            out = subprocess.check_output(
                [qmake, "-query", "QT_INSTALL_PREFIX"],
                text=True, errors="replace").strip()
            if out and Path(out).exists():
                return out
        except Exception:
            pass
    if Path("/usr/lib/cmake/Qt6").exists():
        return "/usr"
    return ""


def _resolve_qt_dir(qt_dir_arg: str, kit: str) -> str:
    """--qt > $QT_DIR > 自动探测，并补全 Linux 工具链子目录。"""
    qt_dir = qt_dir_arg or os.environ.get("QT_DIR", "")
    if not qt_dir:
        qt_dir = _default_qt_dir()
    if qt_dir:
        qt_dir = os.path.expanduser(qt_dir)
        qt_dir = common.qt_kit_dir(qt_dir, kit)
    return qt_dir


def main():
    parser = argparse.ArgumentParser(
        prog="qoolui_build_linux.py",
        description="QoolUI Linux 构建/测试/部署工具（GCC/Clang）")
    parser.add_argument("command", choices=common.COMMANDS,
                        help="命令: configure/build/test/run/install/deploy/release")
    parser.add_argument("--kit", choices=LINUX_KITS, default="gcc",
                        help="编译方式（默认 gcc）")
    parser.add_argument("--type", choices=common.TYPES, default="debug",
                        help="构建类型（默认 debug——开发期默认，xDebug 可见）")
    parser.add_argument("--qt", dest="qt_dir", default=None,
                        help="Qt 路径（版本根或 gcc_64 工具链目录），覆盖 QT_DIR")
    parser.add_argument("--jobs", type=int, default=0, help="并行作业数（默认全部）")
    parser.add_argument("--prefix", default=None, help="install/deploy 前缀")
    parser.add_argument("--version", default=common.DEFAULT_VERSION,
                        help="deploy/release 归档版本号")
    parser.add_argument("extra", nargs="*",
                        help="透传 cmake/ctest/程序参数（须前置 -- 分隔）")
    args = parser.parse_args()
    # positional 已收集 -- 后全部 token；parse_args 不含 -- 分隔符，无需要过滤

    _check_tools(args.kit)
    env = _make_env(args.kit)
    qt_kit = _resolve_qt_dir(args.qt_dir, args.kit)
    if qt_kit:
        env["QT_DIR"] = qt_kit

    kw = dict(qt_dir=qt_kit, jobs=args.jobs, prefix=args.prefix,
              version=args.version, extra=args.extra)
    return common.dispatch(args.command, args.kit, args.type, env=env, **kw)


if __name__ == "__main__":
    sys.exit(main())
