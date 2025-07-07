import QtQuick

Item {
    required property string title
    required property string note
    property Flickable viewBox

    readonly property real viewBoxWidth: viewBox ? viewBox.contentWidth : 200
    readonly property real viewBoxHeight: viewBox ? viewBox.height : 200

    implicitWidth: viewBoxWidth
    implicitHeight: viewBoxHeight
}
