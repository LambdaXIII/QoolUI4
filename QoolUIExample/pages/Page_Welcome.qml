import QtQuick
import Qool

BasicPage {
    id: root

    title: qsTr("欢迎")
    note: qsTr("欢迎使用 QoolUI 4! 一个月前，乐元素也首曝了一款基于UE5研发的大世界都市ARPG：《白银之城》，从官方展示的11分钟实机画面来看，该作的完成度已经相当高了。而在上述两款产品曝光之前，都市开放世界作为国内新兴细分游戏品类的“扛把子”，早已有多款二游新品严阵以待：网易雷火《无限大》，完美世界《异环》，诗悦《望月》，不论是投入力度、重视程度，还是从PV及测试所展示的产品质量来看，一众厂商俨然已将这个品类视作开放世界赛道下一世代的“入场券”。")

    Rectangle {
        anchors.fill: parent
        color: Style.accent
    }
}
