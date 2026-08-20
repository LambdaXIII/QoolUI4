#!/usr/bin/env python3
"""QoolUI 构建工具：Windows 入口。

按编译方式（kit）准备工具链环境后委托 qoolui_build_common：
  msvc  — vswhere 定位 VS 安装 → vcvars64.bat 环境【解析注入】当前进程
          （cmd /c "call vcvars && set" 输出解析——避免 cmd /c 嵌套
          引号转义坑；注入后全部命令直接执行，无 cmd 包装）
  gcc   — MinGW-w64：PATH 前置 Qt 安装的 Tools/mingw*/bin（或使用已
          在 PATH 的 gcc）
  clang — MinGW-clang：PATH 前置 Qt 安装的 Tools/llvm-mingw*/bin

用法:
  python qoolui_build_windows.py <command> [--kit msvc|gcc|clang]
      [--type debug|release] [--qt <Qt 安装根>] [--jobs N]
      [--prefix <install 前缀>] [--version <归档版本>] [-- <cmake 额外参数>]

命令: configure | build | test | run | install | deploy | release
默认: kit=msvc, type=debug（开发期默认 Debug——xDebug 输出可见）。
"""

import argparse
import os
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import qoolui_build_common as common

VSWHERE = (r"C:\Program Files (x86)\Microsoft Visual Studio\Installer"
           r"\vswhere.exe")


def _msvc_vcvars() -> str:
    """vswhere 定位 VS 安装，返回 vcvars64.bat 路径。"""
    if not Path(VSWHERE).exists():
        raise SystemExit(f"vswhere 不存在（{VSWHERE}）——请安装 Visual Studio "
                         "Build Tools（含 C++ 工具集）")
    out = subprocess.check_output([
        VSWHERE, "-latest", "-products", "*",
        "-requires", "Microsoft.VisualStudio.Component.VC.Tools.x86.x64",
        "-property", "installationPath",
    ], text=True).strip()
    if not out:
        raise SystemExit("vswhere 未找到含 C++ 工具集的 VS 安装")
    vcvars = Path(out) / "VC" / "Auxiliary" / "Build" / "vcvars64.bat"
    if not vcvars.exists():
        raise SystemExit(f"vcvars64.bat 不存在（{vcvars}）")
    return str(vcvars)


def _vcvars_env(vcvars: str, qt_dir: str) -> dict:
    """解析 vcvars64.bat 注入的环境变量。

    用 cmd /c "call ... && set" 输出解析——避免 cmd /c 嵌套引号被
    subprocess 参数转义破坏（shell=True 字符串原样传递，无转义）。
    """
    out = subprocess.check_output(
        f'call "{vcvars}" >nul && set', shell=True,
        text=True, errors="replace")
    env = dict(os.environ)
    for line in out.splitlines():
        if "=" in line:
            k, _, v = line.partition("=")
            if k:
                env[k] = v
    if qt_dir:
        env["QT_DIR"] = qt_dir
    return env


def _qt_tool_bin(qt_dir: str, patterns) -> str:
    """在 Qt 安装根下找工具链 bin（Tools/mingw*/bin 等）。

    qt_dir 为工具链目录（C:\\Qt\\6.11.1\\mingw_64）——Qt 官方安装器
    布局：工具链在 C:\\Qt\\Tools\\mingw*/（安装根的父目录下），故取
    parent.parent（Qt 根 → 安装根 C:\\Qt）。
    """
    qt_root = Path(qt_dir).parent.parent if qt_dir else None
    if qt_root:
        tools = qt_root / "Tools"
        for pat in patterns:
            found = sorted(tools.glob(pat))
            if found:
                return str(found[0])
    return ""


def _env_with_path(extra_bin: str, qt_dir: str) -> dict:
    env = os.environ.copy()
    if extra_bin:
        env["PATH"] = extra_bin + os.pathsep + env.get("PATH", "")
    if qt_dir:
        env["QT_DIR"] = qt_dir
    return env


def main():
    parser = argparse.ArgumentParser(
        prog="qoolui_build_windows.py",
        description="QoolUI Windows 构建/测试/部署工具（MSVC/MinGW/Clang）")
    parser.add_argument("command", choices=common.COMMANDS,
                        help="命令: configure/build/test/run/install/deploy/release")
    parser.add_argument("--kit", choices=common.KITS, default="msvc",
                        help="编译方式（默认 msvc）")
    parser.add_argument("--type", choices=common.TYPES, default="debug",
                        help="构建类型（默认 debug——开发期默认，xDebug 可见）")
    parser.add_argument("--qt", dest="qt_dir", default=None,
                        help="Qt 安装根（如 C:\\Qt\\6.11.1），覆盖 QT_DIR")
    parser.add_argument("--jobs", type=int, default=0, help="并行作业数（默认全部）")
    parser.add_argument("--prefix", default=None, help="install/deploy 前缀")
    parser.add_argument("--version", default=common.DEFAULT_VERSION,
                        help="deploy/release 归档版本号")
    parser.add_argument("extra", nargs="*",
                        help="透传 cmake/ctest/程序参数（须前置 -- 分隔）")
    args = parser.parse_args()
    # positional 已收集 -- 后全部 token；parse_args 不含 -- 分隔符，无需要过滤

    qt_kit = common.qt_kit_dir(args.qt_dir or os.environ.get("QT_DIR", ""),
                               args.kit)
    if args.kit == "msvc":
        env = _vcvars_env(_msvc_vcvars(), qt_kit)
    else:
        env = _env_with_path(_qt_tool_bin(qt_kit, (
            "mingw*/bin", "mingw*_64/bin") if args.kit == "gcc"
            else ("llvm-mingw*/bin", "mingw-clang*/bin")), qt_kit)

    kw = dict(qt_dir=qt_kit, jobs=args.jobs, prefix=args.prefix,
              version=args.version, extra=args.extra)
    return common.dispatch(args.command, args.kit, args.type, env=env, **kw)


if __name__ == "__main__":
    sys.exit(main())
