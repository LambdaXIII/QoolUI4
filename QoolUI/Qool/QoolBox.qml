import QtQuick
import QtQuick.Shapes
import Qool

// 八边形背景盒：形状渲染 + 内容内缩布局量 + 精确命中判定。外观经 settings
// （QoolBoxSettings）统一配置、样式默认跟随 Style；settings/control 均为
// 可替换 QObject 引用（替换 settings 绑定链路自动重挂）；curved 且四角 cut
// 满足判定且无填充通道且 animatingHint=false 时退行为原生圆角 Rectangle
// （性能模式）。详细契约见 docs/reference/Qool/QoolBox.md。
Item {
    id: root

    // 外观设置（四角切角/边框/填充/偏移/圆角开关），默认跟随 Style
    property QoolBoxSettings settings: QoolBoxSettings {
        borderWidth: root.Style.controlBorderWidth
        borderColor: root.Style.accent
        fillColor: root.Style.dark
    }
    // 八边形几何单元（可替换/共享；默认 target = 自身）
    property QoolBoxShapeControl control: QoolBoxShapeControl {
        target: root
        settings: root.settings
    }
    // 填充到八边形内部区域的任意 Item（纹理填充；非空时排除退行）
    property Item fillItem: null
    // 渐变填充通道（默认 null——纯色；fillItem 优先于渐变；非空时排除退行——
    // Rectangle 渐变与 Shape 渐变不兼容，退行形态保持"无填充通道"语义；
    // ShapePath.fillGradient 要求 ShapeGradient 新 API，旧 Gradient 不可用）
    property ShapeGradient fillGradient: null

    readonly property alias shape: loader.item

    // 动画提示：true 时跳过退行判定（保持 Shape 渲染）
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
