// 页面宿主框架：按 page_url 经 Loader 异步装载示例页，提供标题/说明
// 标签、加载进度条与滚动视口，并承载页内 QoolTipPanel 提示层。
//
// 刻意设计：
// - tipPanel 是 Flickable 的直接子项（视口坐标），滚动内容时不跟随
//   移动——提示固定在视口右下角，滚动后仍可见；若需提示跟随内容，
//   应把 parent 改为 pageLoader.item 并补偿 contentY 偏移（勿改回
//   内容坐标，滚动后提示会滚出视口）。
// - Loader 加载失败时恢复 loadingBar（否则进度条永久停留）并把标题
//   置为 "页面加载失败"、附注置为 source，避免页面空白无反馈。
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qool.Controls
import Qool.Controls.Components
import Qool
import Qool.Chat
import "pages/components"

BasicControl {
    id: root

    property url page_url

    backgroundSettings {
        fillColor: Style.shadow
    }

    signal pageLoaded

    QtObject {
        id: pCtrl
        property string title
        property string note
    }

    titleItem: ColumnLayout {
        spacing: 2
        anchors {
            top: parent.top
            right: parent.right
            margins: root.backgroundSettings.borderWidth + 2
        }
        width: root.width - (root.backgroundSettings.borderWidth + 2) * 2 - root.backgroundSettings.cutSpaceOnLeft

        BasicBigTitleText {
            text: pCtrl.title
            Layout.alignment: Qt.AlignRight
            topPadding: 4
            rightPadding: 6
        }
        BasicDecorativeText {
            text: pCtrl.note
            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
            Layout.alignment: Qt.AlignRight
            Layout.maximumWidth: parent.width
            rightPadding: 6
        }
    }//titleItem

    contentPadding: 6
    contentItem: Flickable {
        id: main

        clip: true
        boundsBehavior: Flickable.StopAtBounds
        synchronousDrag: false

        contentWidth: width
        contentHeight: pageLoader.height

        ScrollBar.vertical: ScrollBar {}

        Loader {
            id: pageLoader
            asynchronous: true
            width: main.contentWidth
            source: root.page_url
            onLoaded: {
                // pCtrl.title = item.title;
                // pCtrl.note = item.note;
                item.viewBox = main;
                root.pageLoaded();
                main.contentY = 0;
            }
            onStatusChanged: {
                tipPanel.hide();
                // 加载失败：恢复 loadingBar（否则进度条永久停留）并
                // 给出可读错误信息，避免页面空白无反馈
                if (pageLoader.status === Loader.Error) {
                    loadingBar.visible = false;
                    pCtrl.title = qsTr("页面加载失败");
                    pCtrl.note = pageLoader.source;
                }
            }
        }
    } //contentItem

    QoolTipPanel {
        id: tipPanel
        parent: main
        // 刻意设计：tipPanel 是 Flickable 的直接子项（视口坐标），
        // 滚动内容时不跟随移动——提示固定在视口右下角，滚动后仍可见。
        // 若需提示跟随内容，应把 parent 改为 pageLoader.item 并补偿
        // contentY 偏移（不要改回内容坐标——滚动后提示会滚出视口）。
        maximumWidth: parent.width / 2
        maximumHeight: parent.height
        enabled: pageLoader.item
    }

    Popup {
        id: loadingBar
        contentItem: ProgressBar {
            value: pageLoader.progress
            highlightColor: root.Style.accent
            radius: 0
        }
        padding: 0
        background: Item {}
        width: parent.width - Style.controlBorderWidth * 2
        height: 15
        x: Style.controlBorderWidth
        y: parent.height - height - Style.controlBorderWidth
        closePolicy: Popup.NoAutoClose
        popupType: Popup.Item
    }

    Connections {
        target: pageLoader
        function onLoaded() {
            // if (pageLoader.status != Loader.Loading)
            loadingBar.visible = false;
        }
    }

    Connections {
        target: root
        function onPage_urlChanged() {
            loadingBar.visible = true;
        }
    }

    Binding {
        when: (!loadingBar.visible) && (pageLoader.item)
        restoreMode: Binding.RestoreValue
        pCtrl.title: pageLoader.item.title
        pCtrl.note: pageLoader.item.note
    }
}
