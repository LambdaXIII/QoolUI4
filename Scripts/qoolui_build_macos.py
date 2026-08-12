#!/usr/bin/env python3
"""QoolUI 构建工具：macOS 入口（骨架）。

真平台落地时完善：Xcode 工具链定位（xcode-select）、macdeployqt 部署
惯例、Qt 安装路径约定（~/Qt/...）。当前仅提供命令面占位。
"""

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import qoolui_build_common as common


def main():
    raise SystemExit(
        "qoolui_build_macos.py 尚未实现——macOS 平台落地时完善"
        "（Xcode 工具链定位 + macdeployqt）")


if __name__ == "__main__":
    sys.exit(main())
