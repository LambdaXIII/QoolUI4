#!/usr/bin/env python3
"""QoolUI 构建工具：Linux 入口（骨架）。

真平台落地时完善：clang/gcc 工具链定位（PATH/CC/CXX）、Qt 安装路径
约定、部署惯例。当前仅提供命令面占位。
"""

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import qoolui_build_common as common


def main():
    raise SystemExit(
        "qoolui_build_linux.py 尚未实现——Linux 平台落地时完善"
        "（clang/gcc 工具链定位）")


if __name__ == "__main__":
    sys.exit(main())
