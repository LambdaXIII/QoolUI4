import QtQuick
import QtQuick.Shapes
import Qool

/*!
    \qmltype QoolBox
    \inqmlmodule Qool
    \brief 八边形背景盒：形状渲染 + 内容内缩布局量 + 精确命中判定。

    默认渲染八边形（\l OctagonShape/\l OctagonCurvedShape，经 \c settings
    的 \c curved 切换直角/圆角）；外观经 \c settings（\l QoolBoxSettings）
    统一配置（四角切角/边框/填充/偏移/圆角开关），样式默认跟随
    \l Style（\c controlBorderWidth/\c accent/\c dark），可覆盖个别字段。

    \section1 settings 与 control

    \c settings 与 \c control（\l QoolBoxShapeControl）都是公开可替换属性：
    \list
    \li 替换 \c settings 实例（如 \c qbox.settings: otherBox.settings）——
        绑定链路自动重挂（QObject 引用语义：整组赋值共享实例，独立副本
        = 新建实例）；
    \li 替换/共享 \c control（注入自定义兼容类型）——共享需同一几何源
        （尺寸一致或自行设置 target；control 的 target 唯一，默认是创建
        它的 QoolBox）。
    \endlist

    \section1 内容内缩量（*Space）

    \c topSpace/\c bottomSpace/\c leftSpace/\c rightSpace 转发
    \c control 的内容内缩布局量（宿主排版 padding 用），公式
    \c max(0, max(相邻 cut) − (used − 期望)/2)。同系组件（如
    \l {Qool.Controls.Components::QoolBGBox}{QoolBGBox}）覆盖同名属性
    是期望行为（同系同类语义，覆盖含自身布局调整）。

    \section1 退行（性能模式）

    \c curved 为 true 且 \c settings 的四角 cut 满足判定（全 ≤ 短边一半，
    或全 0）、\c fillItem 与 \c fillGradient 均为空且 \c animatingHint 为
    false 时，退行为原生圆角矩形（Rectangle，四角 cut* 作圆角半径、offset
    作 x/y）——非 Shape 渲染，性能最优。\c animatingHint 为 true（动画
    期间）跳过退行判定，保持 Shape 渲染。

    \section1 命中判定

    containmentMask 委托当前变体：直角变体走 \c control 的 O(1) 线性
    不等式（切角不命中）；圆角变体走路径填充判定；退行矩形为矩形判定。

    \section1 纹理填充

    \l {fillItem} {fillItem} 为填充到八边形内部区域的任意 Item
    （Qt 6.8 ShapePath::fillItem，如 Image 或 ShaderEffectSource）；
    \l {fillGradient} {fillGradient} 为渐变填充通道（fillItem 优先于
    渐变）。fillItem/fillGradient 任一非空时退行判定被排除。
*/
Item {
    id: root

    /*! \qmlproperty QoolBoxSettings 外观设置（四角切角/边框/填充/偏移/圆角开关），默认跟随 Style。 */
    property QoolBoxSettings settings: QoolBoxSettings {
        borderWidth: root.Style.controlBorderWidth
        borderColor: root.Style.accent
        fillColor: root.Style.dark
    }
    /*! \qmlproperty QoolBoxShapeControl 八边形几何单元（可替换/共享；默认 target = 自身）。 */
    property QoolBoxShapeControl control: QoolBoxShapeControl {
        target: root
        settings: root.settings
    }
    /*! \qmlproperty Item 填充到八边形内部区域的任意 Item（纹理填充；非空时排除退行）。 */
    property Item fillItem: null
    /*! \qmlproperty ShapeGradient 渐变填充通道（默认 null——纯色；fillItem 优先于渐变；非空时排除退行——Rectangle 渐变与 Shape 渐变不兼容，退行形态保持"无填充通道"语义）。注意：ShapePath.fillGradient 官方要求 ShapeGradient 新 API（LinearGradient 等），旧 Gradient 类型不可用。 */
    property ShapeGradient fillGradient: null

    readonly property alias shape: loader.item

    /*! \qmlproperty bool 动画提示：true 时跳过退行判定（保持 Shape 渲染）。 */
    property bool animatingHint: false

    readonly property real topSpace: root.control.topSpace
    readonly property real bottomSpace: root.control.bottomSpace
    readonly property real leftSpace: root.control.leftSpace
    readonly property real rightSpace: root.control.rightSpace

    SmartObject {
        id: pCtrl

        // 变体组件内直接绑定 root.control/fillItem（组件作用域可引用外层
        // root）：required control 在组件创建时即满足（无注入时序问题——
        // Loader 完成后的 Binding 注入会与 required 检查死锁）；settings
        // 经 control.settings 消费，无需注入。
        Component {
            id: boxShape
            OctagonShape {
                control: root.control
                fillItem: root.fillItem
                fillGradient: root.fillGradient
            }
        }

        Component {
            id: roundShape
            OctagonCurvedShape {
                control: root.control
                fillItem: root.fillItem
                fillGradient: root.fillGradient
            }
        }

        // 退行形态（内联，非 Shape）：原生圆角矩形——cut* 作四角圆角
        // 半径、offset 作 x/y、边框/填充读 settings；无 control、无
        // fillItem 能力（fillItem 非空时 Loader 判定排除本分支）。
        Component {
            id: rectShape
            Rectangle {
                id: rectRoot
                width: parent.width
                height: parent.height
                x: root.settings.offsetX
                y: root.settings.offsetY
                topLeftRadius: root.settings.cutSizeTL
                topRightRadius: root.settings.cutSizeTR
                bottomLeftRadius: root.settings.cutSizeBL
                bottomRightRadius: root.settings.cutSizeBR
                color: root.settings.fillColor
                border.color: root.settings.borderColor
                border.width: root.settings.borderWidth
            }
        }
    }

    Loader {
        id: loader
        anchors.fill: parent
        sourceComponent: {
            if (root.animatingHint == false) {
                let cond1 = !root.fillItem && !root.fillGradient && root.settings.curved;
                const half = Math.min(root.width, root.height) / 2;
                let cond2 = root.settings.cutSizeTL <= half
                    && root.settings.cutSizeTR <= half
                    && root.settings.cutSizeBL <= half
                    && root.settings.cutSizeBR <= half;
                let cond3 = root.settings.cutSizeTL === 0
                    && root.settings.cutSizeTR === 0
                    && root.settings.cutSizeBL === 0
                    && root.settings.cutSizeBR === 0;
                if (cond1 && (cond2 || cond3))
                    return rectShape;
            }
            return root.settings.curved ? roundShape : boxShape;
        }
    }

    containmentMask: loader.item
}
