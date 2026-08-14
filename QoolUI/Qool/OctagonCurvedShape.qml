import QtQuick
import QtQuick.Shapes
import Qool

/*!
    \qmltype OctagonCurvedShape
    \inqmlmodule Qool
    \brief 八边形圆角形状基元（低级组成件）：边框环 + 内部填充。

    低级 API 组件（spec D5）：\c required 整个 \l QoolBoxShapeControl
    注入（\c control 属性），纯消费、不持有几何——独立使用不自洽是
    刻意的（供 \l QoolBox 组装；宿主直接实例化必须注入 control）。
    原 OctagonRoundedShape（改名对齐 \c settings.curved）。

    \section1 圆角半径

    外弧半径 = \c control.settings 对应角 \c cut*（cutSizeTR 对应右上角等）；
    内弧半径 = 内环相邻点弦长/√2（Shape 自身从 \c control 的内环点推出，
    control 不提供派生属性）——cut 为 0 时弦长 0 → 半径 0（退化自洽）。

    \section1 命中判定

    \c containsMode: Shape.FillContains——路径填充判定（圆角精确命中；
    不用直线判定）。

    \section1 纹理填充

    同 \l OctagonShape（\c fillItem 纹理填充）。
*/
Shape {
    id: root

    /*! \qmlproperty QoolBoxShapeControl 八边形控制点计算源（required——宿主注入，供 QoolBox 组装）。 */
    required property QoolBoxShapeControl control
    /*! \qmlproperty Item 填充到八边形内部区域的任意 Item（Qt 6.8 ShapePath::fillItem）。 */
    property alias fillItem: fillShape.fillItem

    OctagonCurvedExternalShapePath {
        control: root.control
        fillColor: root.control.settings.borderColor
    }

    OctagonCurvedInternalShapePath {
        id: fillShape
        control: root.control
        fillColor: root.control.settings.fillColor
    }

    containsMode: Shape.FillContains
}
