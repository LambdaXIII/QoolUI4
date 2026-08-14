import QtQuick
import Qool

/*!
    \qmltype CutSizeBinding
    \inqmlmodule Qool
    \brief 在源与目标对象之间同步角部裁剪尺寸（cutSize*）的绑定工具。

    以 \c from 的 \c cutSizeTL/TR/BL/BR 为源，向 \c to 的对应属性写入。
    \c bindingMode 为 \c AllCorners 时四个角全部同步；为
    \c TopLeftCornerOnly 时仅同步左上角。\c when 为 false、源或目标
    缺少对应属性时，相应绑定不激活。

    用于跨对象同步四角切角（如两个 \l QoolBoxSettings 实例之间保持
    四角一致）；源/目标为任意提供 \c cutSizeTL/TR/BL/BR 属性的对象。
*/
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
        value: root.from.cutSizeBL
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
        value: root.from.cutSizeBR
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
