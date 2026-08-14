// QoolBox 形状（八边形）交互演示页：左侧画布实时渲染 QoolBox，
// 尺寸/角部裁剪/边框/填充/偏移/圆角全部随右侧控制面板联动，
// OctagonShapeHud 叠加显示外/内部控制点。
//
// 刻意设计（修复说明）：面板的 "Dump信息至控制台" 经 wannaDumpInfo
// 信号直达 box_shape.control.dumpInfo()——QoolBox 直接暴露 control
// 属性（QoolBoxShapeControl），无需中间转发层。
import QtQuick
import QtQuick.Controls
import Qool
import Qool.Controls
import "components"
import Qool.Debug

BasicPage {
    id: root
    title: qsTr("QoolBox")
    note: qsTr("酷酷的 Box")

    SplitView {
        id: cc
        anchors.fill: parent

        Item {
            id: shapeFace
            SplitView.fillHeight: true
            SplitView.fillWidth: true
            clip: true

            QoolBox {
                id: box_shape
                anchors.centerIn: parent
                width: control.shapeWidth
                height: control.shapeHeight

                settings {
                    borderWidth: control.borderWidth
                    cutSizeTL: control.cutSizeTL
                    cutSizeBL: control.cutSizeBL
                    cutSizeTR: control.cutSizeTR
                    cutSizeBR: control.cutSizeBR
                    fillColor: control.fillColor
                    borderColor: control.borderColor
                    offsetX: control.offsetX
                    offsetY: control.offsetY
                    // curved 别名撤销（spec D4）——经 settings 访问
                    //（QoolUIExample 不在兼容范围，改动处注释标记）
                    curved: control.rounded
                }

                // QoolBoxHud 须直接作 QoolBox 子项（box 属性默认 parent）
                // ——原 OctagonShapeHud 挂 shape 的方案随重定位同步
                //（QoolUIExample 不在兼容范围，改动处注释标记）
                QoolBoxHud {
                    id: hud
                    showExtPoints: control.showExtPoints
                    showIntPoints: control.showIntPoints
                }
            }

            z: -1
        }

        QoolBoxShapeControlPanel {
            id: control
            SplitView.fillHeight: true
            SplitView.preferredWidth: implicitWidth
            onWannaDumpInfo: box_shape.control.dumpInfo()
        }
    } //cc
}
