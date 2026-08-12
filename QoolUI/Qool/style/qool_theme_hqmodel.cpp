#include "qool_theme_hqmodel.h"

#include "qool_theme_db.h"

QOOL_NS_BEGIN

/*!
    \qmltype ThemeHQModel
    \inqmlmodule Qool
    \nativetype qoolui::ThemeHQModel
    \brief 主题总览列表模型（普通类型，非单例）。

    继承 \c QIdentityProxyModel，构造时自动挂接主题数据库
    （ThemeDB 全局单例）为源模型——直接以 \c model 属性绑定到视图即可
    展示全部已安装主题（row = 主题）。roles 与源模型一致：

    \table
    \header \li Role \li 内容
    \row \li \c name \li 主题名（\c display 同值）
    \row \li \c theme \li 完整主题值（\l Theme）
    \row \li \c metadata \li 元数据映射
    \row \li \c constants / \c active / \c inactive / \c disabled / \c custom
        \li 对应分组的扁平映射
    \endtable

    \note \c metadata role 当前源模型 \c data() 未提供取值（返回空）——
    视图需要元数据时请改用 \c theme role 经 \l Theme 的 \c metadata()
    方法读取。

    \section1 实时性

    安装主题（\c installTheme）时源模型发出 \c rowsInserted，经
    \c QAbstractProxyModel 原生转发——视图无需手动刷新；\c dataChanged/
    \c modelReset 等其余变更通知同理。多视图场景各自实例化本类型，
    数据始终一致（同一源模型）。
*/

ThemeHQModel::ThemeHQModel(QObject* parent)
  : QIdentityProxyModel(parent) {
  setSourceModel(ThemeDB::instance());
}

QOOL_NS_END
