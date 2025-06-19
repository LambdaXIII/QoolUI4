pragma Singleton

import QtQuick
import Qool

SmartObject {
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

    readonly property alias positions: _positions
    SmartObject {
        id: _positions
        readonly property list<int> leftSide: [Qore.TopLeft, Qore.LeftTop, Qore.LeftCenter, Qore.LeftBottom, Qore.BottomLeft]
        readonly property list<int> rightSide: [Qore.TopRight, Qore.RightTop, Qore.RightCenter, Qore.RightBottom, Qore.BottomRight]
        readonly property list<int> topSide: [Qore.TopLeft, Qore.TopCenter, Qore.TopRight, Qore.LeftTop, Qore.RightTop]
        readonly property list<int> bottomSide: [Qore.BottomLeft, Qore.BottomCenter, Qore.BottomRight, Qore.LeftBottom, Qore.RightBottom]
        readonly property list<int> leftEdge: [Qore.LeftTop, Qore.LeftCenter, Qore.LeftBottom]
        readonly property list<int> rightEdge: [Qore.RightTop, Qore.RightCenter, Qore.RightBottom]
        readonly property list<int> topEdge: [Qore.TopLeft, Qore.TopCenter, Qore.TopRight]
        readonly property list<int> bototmEdge: [Qore.BottomLeft, Qore.BottomCenter, Qore.BottomRight]
        readonly property list<int> hCenter: [Qore.LeftCenter, Qore.RightCenter, Qore.Center]
        readonly property list<int> vCenter: [Qore.TopCenter, Qore.BottomCenter, Qore.Center]

        function xPosFromWidth(width: real, position: int): real {
            if (leftSide.includes(position))
                return 0.0;
            if (rightSide.includes(position))
                return width;
            if (hCenter.includes(position))
                return width / 2.0;
            return 0.0;
        }

        function yPosFromHeight(height: real, position: int): real {
            if (topSide.includes(position))
                return 0.0;
            if (bottomSide.includes(position))
                return height;
            if (vCenter.includes(position))
                return height / 2.0;
            return 0.0;
        }

        function posInRect(item, position: int): point {
            const xpos = xPosFromWidth(item.width);
            const ypos = yPosFromHeight(item.height);
            return Qt.point(xpos, ypos);
        }

        function xOffsetToPos(width: real, position: int): real {
            return xPosFromWidth(width, position) * -1;
        }

        function yOffsetToPos(height: real, position: int): real {
            return yPosFromHeight(height, position) * -1;
        }

        function offsetToPos(item, position: int): vector2d {
            const xoffset = xOffsetToPos(item.width, position);
            const yoffset = yOffsetToPos(item.height, position);
            return Qt.vector2d(xoffset, yoffset);
        }
    } //_positions

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
