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

        function xPosInRect(item, position: int): real {
            if (leftSide.includes(position))
                return item.x;
            if (rightSide.includes(position))
                return item.x + item.width;
            if (hCenter.includes(position))
                return item.x + item.width / 2;
            return 0.0;
        }

        function yPosInRect(item, position: int): real {
            if (topSide.includes(position))
                return item.y;
            if (bottomSide.includes(position))
                return item.y + item.height;
            if (vCenter.includes(position))
                return item.y + item.height / 2;
            return 0.0;
        }

        function posInRect(item, position: int): point {
            const xpos = xPosInRect(item);
            const ypos = yPosInRect(item);
            return Qt.point(xpos, ypos);
        }

        function xOffsetToPos(item, position: int): real {
            if (leftSide.includes(position))
                return 0;
            if (rightSide.includes(position))
                return item.width * -1;
            if (hCenter.includes(position))
                return item.width / -2;
            return 0;
        }

        function yOffsetToPos(item, position: int): real {
            if (topSide.includes(position))
                return 0;
            if (bottomSide.includes(position))
                return item.height * -1;
            if (vCenter.includes(position))
                return item.height / -2;
            return 0;
        }

        function offsetToPos(item, position: int): vector2d {
            const xoffset = xOffsetToPos(item, position);
            const yoffset = yOffsetToPos(item, position);
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
