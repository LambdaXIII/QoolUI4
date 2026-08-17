// Playground：测试场——Qool.Controls 控件的调试用例（仓库开发模式：
// 可随意更改，不保留旧内容）。
//
// 当前含 EditableTextBox 调试用例（EditableText 密码回显调试用例已
// 迁移 Page_InputControls 正式展示页）。
import QtQuick
import Qool
import Qool.Controls
import Qool.Debug
import QtQuick.Layouts

BasicPage {
    id: root

    title: qsTr("测试场")
    note: qsTr("调试用例（当前为空）")

    // EditableTextBox 调试用例：多行输入 + 垂直滚动（滚动条 Qool 主题
    // ScrollBar——非 Qt 默认样式）。
    // QoolControl {
    //     title: qsTr("酷酷的文本框")
    //     contentItem: ColumnLayout {
    //         EditableTextBox {
    //             Layout.fillWidth: true
    //             Layout.fillHeight: true
    //             text: qsTr("多行文本输入：\n回车换行；\n内容超出视口高度时出现垂直滚动条（Qool 主题）。\n滚动条可拖动，鼠标滚轮亦可滚动。\n回车换行；\n内容超出视口高度时出现垂直滚动条（Qool 主题）。\n滚动条可拖动，鼠标滚轮亦可滚动。\n回车换行；\n内容超出视口高度时出现垂直滚动条（Qool 主题）。\n滚动条可拖动，鼠标滚轮亦可滚动。\n回车换行；\n内容超出视口高度时出现垂直滚动条（Qool 主题）。\n滚动条可拖动，鼠标滚轮亦可滚动。\n回车换行；\n内容超出视口高度时出现垂直滚动条（Qool 主题）。\n滚动条可拖动，鼠标滚轮亦可滚动。")
    //             readOnly: readonlyBtn.checked
    //         }

    //         ClickableText {
    //             id: readonlyBtn
    //             text: qsTr("可写")
    //             checkedText: qsTr("只读")
    //             checkable: true
    //             Layout.fillWidth: true
    //         }
    //     }
    //     RectResizer {}
    // }

    HalfCrystal {
        id: tri
        x: 30
        y: 30
        width: 50
        height: 50
        color: Style.accent
        borderColor: Style.negative
        borderWidth: 15
        RectResizer {}
    }

    ClickableText {
        text: "TTT"
        onClicked: {
            if (tri.direction == Qore.N)
                tri.direction = Qore.E;
            else if (tri.direction == Qore.E)
                tri.direction = Qore.S;
            else if (tri.direction == Qore.S)
                tri.direction = Qore.W;
            else if (tri.direction == Qore.W)
                tri.direction = Qore.Unknown;
            else
                tri.direction = Qore.N;
        }
    }
}
