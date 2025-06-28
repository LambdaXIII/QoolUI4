// pragma Singleton

import QtQuick
import QtQml.XmlListModel

XmlListModel {
    id: root

    source: "toc.xml"
    query: "/qoolui_toc/page"

    XmlListModelRole {
        name: "title"
        elementName: "title"
    }
    XmlListModelRole {
        name: "note"
        elementName: "note"
    }
    XmlListModelRole {
        name: "page"
        elementName: "page"
    }
}
