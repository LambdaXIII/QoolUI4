import QtQuick
import Qool

/*!
    \qmltype PaPaWall
    \inqmlmodule Qool.Controls.Components
    \brief 在配色背景上随机轮换显示大字的装饰墙。

    \c highColor/\c lowColor 控制背景与文字颜色，\c words 提供词库
    （默认 Style.papaWords），\c font 与 \c text 控制文字外观与当前内容，
    \c textSizeMode 选择字号策略。调用 \c refresh() 随机换词，并施加
    随机偏移、缩放与 ±45° 旋转。

    \section2 textSizeMode 三模式语义
    \list
    \li \c DependsOnFontSize（默认）：1-2 倍随机缩放，尊重字体设置、
        与控件边缘无关；
    \li \c LargerTextSize：按较大边缘（宽高取大）缩放；
    \li \c SmallerTextSize：按较小边缘（宽高取小）缩放。
    \endlist
    修复说明：旧代码曾引用不存在的 RespectFontSize/LargetTextSize
    枚举成员，运行时 ReferenceError 使功能整体失效；当前有效枚举为
    LargerTextSize / SmallerTextSize / DependsOnFontSize。
*/

Item {
    id: root

    property color highColor: Style.highlight
    property color lowColor: Style.highlightedText

    property list<string> words: Style.papaWords
    property font font
    property alias text: highWord.text

    font.bold: true
    font.pixelSize: Math.round(Math.min(width, height) / 2)

    enum TextSizeMode {
        LargerTextSize,
        SmallerTextSize,
        DependsOnFontSize
    }

    property int textSizeMode: PaPaWall.DependsOnFontSize

    Rectangle {
        anchors.fill: parent
        color: root.highColor
    }

    Text {
        id: highWord
        z: 1
        color: root.lowColor
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        font: root.font
        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: Text.AlignHCenter
    }

    function refresh() {
        const word_index = Math.floor(Math.random() * root.words.length);
        highWord.text = root.words[word_index];

        if (!highWord.text)
            return;
        const v_offset = root.height * 0.75 * (Math.random() - 0.5);
        const h_offset = root.width * 0.75 * (Math.random() - 0.5);
        highWord.anchors.verticalCenterOffset = v_offset;
        highWord.anchors.horizontalCenterOffset = h_offset;

        let words_factor = 1;
        // 三模式语义：DependsOnFontSize（默认）= 1-2 倍随机缩放（尊重字体、
        // 与边缘无关）；Larger/SmallerTextSize = 按较大/较小边缘缩放。
        // 此前此处引用不存在的 RespectFontSize/LargetTextSize 枚举成员，
        // 运行时 ReferenceError 使功能整体失效。
        if (root.textSizeMode === PaPaWall.DependsOnFontSize) {
            words_factor = Math.random() + 1;
        } else {
            let ref_edge = root.textSizeMode === PaPaWall.LargerTextSize ? Math.max(
                                                                               root.width,
                                                                               root.height) :
                                                                           Math.min(root.width,
                                                                                    root.height);
            const words_w = highWord.implicitWidth;
            const words_rand_w = ref_edge * (Math.random() + 0.8);
            words_factor = words_rand_w / words_w;
        }
        highWord.scale = words_factor;

        highWord.rotation = (Math.random() * 90) - 45;
    }
}
