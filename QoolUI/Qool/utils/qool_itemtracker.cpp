#include "qool_itemtracker.h"

#include "qoolcommon/qt_tools.hpp"

#include <QQuickWindow>

/*!
    \qmltype ItemTracker
    \inqmlmodule Qool
    \nativetype qoolui::ItemTracker
    \brief 追踪目标对象所在 item 的有效可用状态与窗口激活状态。

    给定任意 \c target 对象，向上找到其所属 item（QQuickItem）与窗口，
    暴露 \c itemEnabled（有效可用——含祖先链）与 \c windowActived
    （窗口激活；target 未挂窗口时视为 true）。典型用途：Style 按宿主
    状态选择外观组（Active/Inactive/Disabled）。

    \c target 可为任意 QObject（如控件内部对象）；追踪链路自动随
    item/窗口变化重建。

    \section1 信号

    所有属性均经 Qt 自动生成的 \c xxxChanged 信号通知（值守卫：实际值
    变化才发出）。\c itemEnabledChanged / \c windowActivedChanged 是
    状态输出通知；\c targetChanged / \c itemChanged / \c windowChanged
    是链路变化通知。
*/

QOOL_NS_BEGIN

ItemTracker::ItemTracker(QObject* parent)
  : QObject { parent } {
  connect(this, &ItemTracker::targetChanged, this, [&] {
    update_item();
    update_window();
  });

  connect(
    this, &ItemTracker::itemChanged, this, &ItemTracker::setup_item);
  connect(this, &ItemTracker::windowChanged, this,
    &ItemTracker::setup_window);
}

void ItemTracker::update_item() {
  auto t = m_target.value();
  m_item = tools::find_parent<QQuickItem>(t);
}

void ItemTracker::update_window() {
  auto i = m_item.value();
  if (i) {
    m_window = qobject_cast<QWindow*>(i->window());
  } else {
    auto t = m_target.value();
    m_window = tools::find_parent<QWindow>(t);
  }
}

void ItemTracker::setup_item() {
  while (! m_itemConnections.isEmpty()) {
    auto c = m_itemConnections.takeFirst();
    disconnect(c);
  }
  auto i = m_item.value();
  if (i == nullptr)
    return;

  // flow-on 捷径：只监听 item 自身 enabledChanged 即覆盖整条祖先链——
  // enabled 有 flow-on，祖先链任意层变化必反映到 item 自身属性值
  // （无需遍历祖先链逐层监听）。windowChanged 用于窗口归属变化重建。
  m_itemConnections << connect(i, &QQuickItem::enabledChanged, this,
    &ItemTracker::update_item_properties)
                    << connect(i, &QQuickItem::windowChanged, this,
                         &ItemTracker::update_window);

  update_item_properties();
}

void ItemTracker::setup_window() {
  while (! m_windowConnections.isEmpty()) {
    auto c = m_windowConnections.takeFirst();
    disconnect(c);
  }
  auto w = m_window.value();
  if (w == nullptr)
    return;

  m_windowConnections << connect(w, &QWindow::activeChanged, this,
    &ItemTracker::update_window_properties);
  update_window_properties();
}

void ItemTracker::update_item_properties() {
  auto i = m_item.value();
  // 有效 enabled（isEnabled 含祖先链合取）；无 item 时视为启用
  // （null 是「未追踪」而非「禁用」，默认 true 保持正常态语义）。
  bool _enabled = (i == nullptr) || i->isEnabled();
  m_itemEnabled.setValue(_enabled);
}

void ItemTracker::update_window_properties() {
  auto w = m_window.value();
  // 无窗口时视为激活（默认 true：未挂窗口不是「失活」）。
  m_windowActived = w ? w->isActive() : true;
}

QOOL_NS_END
