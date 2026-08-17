#include "qool_itemtracker.h"

#include "qoolcommon/qt_tools.hpp"

#include <QQuickWindow>

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
