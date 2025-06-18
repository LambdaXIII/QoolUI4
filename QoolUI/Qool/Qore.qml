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

    readonly property list<int> positionsOnLeftSide: [Qore.TopLeft, Qore.LeftTop, Qore.LeftCenter, Qore.LeftBottom, Qore.BottomLeft]
    readonly property list<int> positionsOnRightSide: [Qore.TopRight, Qore.RightTop, Qore.RightCenter, Qore.RightBottom, Qore.BottomRight]
    readonly property list<int> positionsOnTopSide: [Qore.TopLeft, Qore.TopCenter, Qore.TopRight, Qore.LeftTop, Qore.RightTop]
    readonly property list<int> positionsOnBottomSide: [Qore.BottomLeft, Qore.BottomCenter, Qore.BottomRight, Qore.LeftBottom, Qore.RightBottom]
    readonly property list<int> positionsOnLeftEdge: [Qore.LeftTop, Qore.LeftCenter, Qore.LeftBottom]
    readonly property list<int> positionsOnRightEdge: [Qore.RightTop, Qore.RightCenter, Qore.RightBottom]
    readonly property list<int> positionsOnTopEdge: [Qore.TopLeft, Qore.TopCenter, Qore.TopRight]
    readonly property list<int> positionsOnBottomEdge: [Qore.BottomLeft, Qore.BottomCenter, Qore.BottomRight]

    function floatString(x, precision = 2, keep_zero = false) {
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
