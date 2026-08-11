#ifndef QOOL_ITEMTRACKER_H
#define QOOL_ITEMTRACKER_H

#include "qoolcommon/qbindable_property_macros.hpp"
#include "qoolns.hpp"

#include <QObject>
#include <QQuickItem>
#include <QWindow>

QOOL_NS_BEGIN

// 状态追踪器：给定 target（任意 QObject），向上找其所属 item 与窗口，
// 暴露有效 enabled（isEnabled——含祖先链合取）与窗口激活状态（无窗口
// 视为 true）。Style 用它按宿主状态选择外观组（Active/Inactive/Disabled）。
// 机制要点（见 .cpp）：
// - itemEnabled 只监听 item 自身 enabledChanged——enabled 有 flow-on，
//   祖先链任意层变化必反映到自身属性值（无需遍历祖先链）
// - window 为 null 时属性取默认 true（无追踪目标视为正常态）
class ItemTracker: public QObject {
  Q_OBJECT
  QML_ELEMENT
public:
  explicit ItemTracker(QObject* parent = nullptr);

protected:
  Q_SLOT void update_item();
  Q_SLOT void update_window();

  Q_SLOT void setup_item();
  QList<QMetaObject::Connection> m_itemConnections;
  Q_SLOT void setup_window();
  QList<QMetaObject::Connection> m_windowConnections;

  Q_SLOT void update_item_properties();
  Q_SLOT void update_window_properties();

  QBINDABLE_WRITABLE_PROPERTY(
    ItemTracker, QObject*, target)
  QBINDABLE_READONLY_PROPERTY(
    ItemTracker, QQuickItem*, item)
  QBINDABLE_READONLY_PROPERTY(
    ItemTracker, QWindow*, window)
  QBINDABLE_READONLY_PROPERTY(
    ItemTracker, bool, itemEnabled)
  QBINDABLE_READONLY_PROPERTY(
    ItemTracker, bool, windowActived)
};

QOOL_NS_END
#endif // QOOL_ITEMTRACKER_H
