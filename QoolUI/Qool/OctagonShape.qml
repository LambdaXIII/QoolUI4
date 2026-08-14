import QtQuick
import QtQuick.Shapes
import Qool

/*!
    \qmltype OctagonShape
    \inqmlmodule Qool
    \brief 八边形直角形状基元（低级组成件）：边框环 + 内部填充 + 精确命中。

    低级 API 组件（spec D5）：\c required 整个 \l QoolBoxShapeControl
    注入（\c control 属性），纯消费（控制点/space/settings）、不持有
    几何——独立使用不自洽是刻意的（供 \l QoolBox 组装；宿主直接实例化
    必须注入 control，样式经 \c control.settings 读取）。四角切角独立
    设置（\c settings.cutSizeTL/TR/BL/BR）。

    \section1 命中判定

    containmentMask 直接挂 \c control（QObject 掩码）——委托
    QoolBoxShapeControl::contains() 的 O(1) 线性不等式判定：切角区域
    点击不命中，且判定不依赖路径填充，性能稳定。offset 平移后判定区
    跟随。

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

    /*! \qmlproperty QoolBoxShapeControl 八边形控制点计算源（required——宿主注入，供 QoolBox 组装）。 */
    required property QoolBoxShapeControl control
    /*! \qmlproperty Item 填充到八边形内部区域的任意 Item（Qt 6.8 ShapePath::fillItem）。 */
    property alias fillItem: fillShape.fillItem
    /*! \qmlproperty ShapeGradient 渐变填充通道（默认 null——纯色；fillItem 优先于渐变）。注意：ShapePath.fillGradient 官方要求 ShapeGradient 新 API（LinearGradient 等），旧 Gradient 类型不可用。 */
    property alias fillGradient: fillShape.fillGradient

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

    // 命中判定委托数值算法（QObject 掩码——AGENTS.md 已知陷阱 5）：
    // 切角不命中；判定区随 offset 平移。
    containmentMask: root.control
}
