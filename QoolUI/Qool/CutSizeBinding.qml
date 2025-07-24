import QtQuick
import Qool

SmartObject {
    id: root

    property var from
    property var to

    enum BindingMode {
        AllCorners,
        TopLeftCornerOnly
    }

    property int bindingMode: CutSizeBinding.AllCorners

    property bool when: true

    Binding {
        id: tlBinding
        target: root.to
        property: "cutSizeTL"
        value: root.from.cutSizeTL
        when: {
            const pName = "cutSizeTL";
            if (!root.when)
                return false;
            if (!root.from)
                return false;
            if (!root.from.hasOwnProperty(pName))
                return false;
            if (!root.to)
                return false;
            if (!root.to.hasOwnProperty(pName))
                return false;
            return true;
        }
    }

    Binding {
        id: trBinding
        target: root.to
        property: "cutSizeTR"
        value: root.from.cutSizeTR
        when: {
            const pName = "cutSizeTR";
            if (!root.when)
                return false;
            if (root.bindingMode !== CutSizeBinding.AllCorners)
                return false;
            if (!root.from)
                return false;
            if (!root.from.hasOwnProperty(pName))
                return false;
            if (!root.to)
                return false;
            if (!root.to.hasOwnProperty(pName))
                return false;
            return true;
        }
    }

    Binding {
        id: blBinding
        target: root.to
        property: "cutSizeBL"
        value: root.from.cutSizeTR
        when: {
            const pName = "cutSizeBL";
            if (!root.when)
                return false;
            if (root.bindingMode !== CutSizeBinding.AllCorners)
                return false;
            if (!root.from)
                return false;
            if (!root.from.hasOwnProperty(pName))
                return false;
            if (!root.to)
                return false;
            if (!root.to.hasOwnProperty(pName))
                return false;
            return true;
        }
    }

    Binding {
        id: brBinding
        target: root.to
        property: "cutSizeBR"
        value: root.from.cutSizeTR
        when: {
            const pName = "cutSizeBR";
            if (!root.when)
                return false;
            if (root.bindingMode !== CutSizeBinding.AllCorners)
                return false;
            if (!root.from)
                return false;
            if (!root.from.hasOwnProperty(pName))
                return false;
            if (!root.to)
                return false;
            if (!root.to.hasOwnProperty(pName))
                return false;
            return true;
        }
    }
}
