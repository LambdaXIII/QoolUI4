#include "qool_itemtracker.h"

#include "qoolcommon/qt_tools.hpp"

#include <QQuickWindow>

QOOL_NS_BEGIN

ItemTracker::ItemTracker(QObject* parent)
  : QObject { parent } {
  // 文档契约：无 item/无窗口视为正常态（enabled/active 默认 true）
  m_itemEnabled.setValue(true);
  m_windowActived.setValue(true);

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
  if (i == nullptr) {
    // 无 item：未追踪 = 正常态（enabled 默认 true）
    m_itemEnabled.setValue(true);
    return;
  }

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
  if (w == nullptr) {
    // 无窗口：未挂窗口不算 inactive
    m_windowActived.setValue(true);
    return;
  }

  m_windowConnections << connect(w, &QWindow::activeChanged, this,
    &ItemTracker::update_window_properties);
  update_window_properties();
}

void ItemTracker::update_item_properties() {
  auto i = m_item.value();
  bool _enabled = (i == nullptr) || i->isEnabled();
  m_itemEnabled.setValue(_enabled);
}

void ItemTracker::update_window_properties() {
  auto w = m_window.value();
  m_windowActived = w ? w->isActive() : true;
}

QOOL_NS_END
