pragma Singleton

import QtQuick

QtObject {
    enum Positions {
        TopLeft,
        TopCenter,
        TopRight,
        LeftTop,
        LeftCenter,
        LeftBottom,
        BottomLeft,
        BottomCenter,
        BottomRight,
        RightTop,
        RightCenter,
        RightBottom,
        Center
    }

    readonly property list<int> positionsOnLeftSide: [Qool.TopLeft, Qool.LeftTop, Qool.LeftCenter, Qool.LeftBottom, Qool.BottomLeft]
    readonly property list<int> positionsOnRightSide: [Qool.TopRight, Qool.RightTop, Qool.RightCenter, Qool.RightBottom, Qool.BottomRight]
    readonly property list<int> positionsOnTopSide: [Qool.TopLeft, Qool.TopCenter, Qool.TopRight, Qool.LeftTop, Qool.RightTop]
    readonly property list<int> positionsOnBottomSide: [Qool.BottomLeft, Qool.BottomCenter, Qool.BottomRight, Qool.LeftBottom, Qool.RightBottom]
    readonly property list<int> positionsOnLeftEdge: [Qool.LeftTop, Qool.LeftCenter, Qool.LeftBottom]
    readonly property list<int> positionsOnRightEdge: [Qool.RightTop, Qool.RightCenter, Qool.RightBottom]
    readonly property list<int> positionsOnTopEdge: [Qool.TopLeft, Qool.TopCenter, Qool.TopRight]
    readonly property list<int> positionsOnBottomEdge: [Qool.BottomLeft, Qool.BottomCenter, Qool.BottomRight]

    function format_float(x, precision = 2, keep_zero = false) {
        // 处理精度为负数的情况
        if (precision < 0)
            precision = 0;

        // 计算四舍五入的值
        const factor = Math.pow(10, precision);
        const rounded = Math.round(x * factor) / factor;

        if (!keep_zero)
            return rounded;

        // 转换为字符串
        let str = rounded.toString();

        // 如果是整数，添加小数点
        if (!str.includes('.')) {
            str += '.';
        }

        // 分割整数和小数部分
        let splitted = str.split('.');
        let integer = splitted[0];
        let decimal = splitted[1];
        return `${integer}.${decimal.padEnd(precision, '0')}`;
    }
}
