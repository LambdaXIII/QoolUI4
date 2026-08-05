import QtQuick
import QtQuick.Shapes
import Qool

/*!
    \qmltype OctagonShape
    \inqmlmodule Qool
    \brief 八边形形状基元：边框环 + 内部填充 + 精确命中判定。

    由 \l QoolBoxShapeControl 计算八边形外部/内部 16 个控制点，
    渲染边框（OctagonExternalShapePath）与填充（OctagonInternalShapePath）
    两层。裁剪尺寸四角统一设置（\l {QoolBoxSettings::cutSizes}
    {cutSizes}），也可四角独立（\c cutSizeTL/TR/BL/BR）。

    \section1 命中判定

    containmentMask 使用 \l ShapeContainmentMask 委托
    QoolBoxShapeControl::contains() 的 O(1) 线性不等式判定——
    切角区域点击不命中，且判定不依赖路径填充，性能稳定。
    位移（offsetX/offsetY）后判定区跟随。

    \note 圆角形态的数值判定尚未实现：圆角形状（OctagonRoundedShape）
    走 Shape.FillContains 路径判定。

    \section1 纹理填充

    \l {fillItem} {fillItem} 即 V3 CutCornerImage 的替代路径：
    Qt 6.8 起 ShapePath 支持任意 Item 纹理填充（fillItem），
    将任意 Item 填充到八边形内部区域，比位图切角方案更泛化。
    填充源需是可纹理化的 item（如 Image 或 ShaderEffectSource）；
    普通 item 树需要分层渲染（如 ShaderEffectSource）才能被
    纹理化。
*/
Shape {
    id: root

    /*! \qmlproperty QoolBoxSettings 形状外观设置（裁剪尺寸/边框/填充/偏移）。 */
    property QoolBoxSettings settings: QoolBoxSettings {
        // borderWidth: 10
    }
    /*! \qmlproperty QoolBoxShapeControl 八边形控制点计算器（只读，随 settings 联动）。 */
    readonly property QoolBoxShapeControl control: QoolBoxShapeControl {
        settings: root.settings
        target: root
    }
    /*! \qmlproperty Item 填充到八边形内部区域的任意 Item（Qt 6.8 ShapePath::fillItem）。 */
    property alias fillItem: fillShape.fillItem

    OctagonExternalShapePath {
        id: borderShape
        control: root.control
        strokeWidth: 0
        strokeColor: "transparent"
        fillColor: root.control.settings.borderColor
    }

    OctagonInternalShapePath {
        id: fillShape
        control: root.control
        strokeWidth: 0
        strokeColor: "transparent"
        fillColor: root.control.settings.fillColor
    }

    // 命中判定委托数值算法：切角不命中；圆角形态暂走 FillContains（见类型文档）
    containmentMask: ShapeContainmentMask {
        control: root.control
    }
}
