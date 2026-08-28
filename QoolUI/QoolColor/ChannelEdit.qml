import QtQuick
import QtQuick.Controls.Basic
import Qool
import Qool.Controls
import Qool.Color
import "_private"

Control {
    id: root

    property int channel: ColorHQ.HSLHue

    property ColorAssistant colorAssistant: ColorAssistant {
        color: Style.accent
    }

    property real value

    property bool readOnly: false

    property int orientation: Qt.Horizontal
    readonly property bool horizontal: orientation === Qt.Horizontal
    readonly property bool vertical: orientation === Qt.Vertical

    property bool tagOnTop: false

    contentItem: Item {
        id: contentBox

        implicitWidth: root.horizontal ? tag.implicitWidth + editor.width + 5 : Math.max(tag.implicitWidth, editor.width)
        implicitHeight: root.horizontal ? Math.max(tag.implicitHeight, editor.implicitHeight) : tag.implicitHeight + editor.implicitHeight

        ColorNumText {
            id: tag
            objectName: "tag"
            text: root.vertical ? ColorHQ.channelTagShort(root.channel) : ColorHQ.channelTag(root.channel)
            color: Style.buttonText
            horizontalAlignment: Text.AlignHCenter
        }

        EditableText {
            id: editor
            objectName: "editor"
            Style.animationEnabled: false
            readOnly: root.readOnly
            font: PixelFont.normal

            // 只验浮点格式不设范围（范围/补点语义由 parseChannelNumberFloat 承担）。
            validator: RegularExpressionValidator {
                regularExpression: /^[+-]?(\d+(\.\d*)?|\.\d+)$/
            }

            // displayItem 是 alias 子对象，PropertyChanges 无法寻址——此处唯一形态绑定。
            displayItem: ColorNumText {
                horizontalAlignment: root.horizontal ? (root.mirrored ? Text.AlignLeft : Text.AlignRight) : Text.AlignHCenter
            }

            textFromEditText: function (s) {
                let v = ColorHQ.parseChannelNumberFloat(s);
                if (Number.isNaN(v))
                    v = proxy.value;
                else
                    root.value = v;
                return ColorHQ.formatChannelNumberFloat(v);
            }

            width: textMetrics.advanceWidth("0000")
        }

        states: [
            State {
                name: "hPlain"
                when: root.horizontal && !root.mirrored
                PropertyChanges {
                    tag.x: 0
                    tag.y: 0
                    tag.width: Math.max(0, contentBox.width - editor.width - 5)
                    tag.height: contentBox.height
                    tag.horizontalAlignment: Text.AlignLeft
                    editor.x: contentBox.width - editor.width
                    editor.y: 0
                    editor.height: contentBox.height
                }
            },
            State {
                name: "hMirrored"
                when: root.horizontal && root.mirrored
                PropertyChanges {
                    tag.x: contentBox.width - tag.width
                    tag.y: 0
                    tag.width: Math.max(0, contentBox.width - editor.width - 5)
                    tag.height: contentBox.height
                    tag.horizontalAlignment: Text.AlignRight
                    editor.x: 0
                    editor.y: 0
                    editor.height: contentBox.height
                }
            },
            // 竖直：短标签在上 + 数字在下，均水平居中
            State {
                name: "vPlain"
                when: root.vertical && !root.tagOnTop
                PropertyChanges {
                    tag.x: Math.max(0, (contentBox.width - tag.width) / 2)
                    tag.y: 0
                    tag.width: tag.implicitWidth
                    tag.height: tag.implicitHeight
                    editor.x: Math.max(0, (contentBox.width - editor.width) / 2)
                    editor.y: tag.height
                    editor.height: editor.displayItem.implicitHeight
                }
            },
            State {
                name: "vFlipped"
                when: root.vertical && root.tagOnTop
                PropertyChanges {
                    tag.x: Math.max(0, (contentBox.width - tag.width) / 2)
                    tag.y: editor.height
                    tag.width: tag.implicitWidth
                    tag.height: tag.implicitHeight
                    editor.x: Math.max(0, (contentBox.width - editor.width) / 2)
                    editor.y: 0
                    editor.height: editor.displayItem.implicitHeight
                }
            }
        ]
    }

    FontMetrics {
        id: textMetrics
        font: PixelFont.normal
    }

    PropertyProxy {
        id: proxy
        target: root.colorAssistant
        property: ColorHQ.channelNameF(root.channel)
    }

    // 手动同步（绑定求值早于 proxy 观察建立，不依赖引擎求值序）；编辑基准
    // 仅非编辑态写（用户输入优先）。播种于 onCompleted。
    function update_display() {
        let s = ColorHQ.formatChannelNumberFloat(proxy.value);
        editor.displayItem.text = s;
        if (!editor.editing)
            editor.text = s;
    }

    // 双向同步：读 assistant → root.value + update_display；写编辑收尾/外部
    // → assistant。文本编辑离散写一次、同值守卫收敛，无需 slider 族互斥门控。
    Connections {
        target: proxy
        function onValueChanged() {
            root.value = proxy.value;
            update_display();
        }
    }
    Connections {
        target: root
        function onValueChanged() {
            proxy.value = root.value;
        }
    }

    Component.onCompleted: update_display()
}
