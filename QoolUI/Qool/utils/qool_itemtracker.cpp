#include "qool_itemtracker.h"

#include "qoolcommon/debug.hpp"
#include "qoolcommon/qt_tools.hpp"

#include <QQuickWindow>

QOOL_NS_BEGIN

ItemTracker::ItemTracker(QObject* parent)
  : QObject { parent } {
  connect(this, SIGNAL(targetChanged()), this, SLOT(update_item()));
  connect(this, SIGNAL(targetChanged()), this, SLOT(update_window()));
  connect(this, SIGNAL(itemChanged()), this, SLOT(setup_item()));
  connect(this, SIGNAL(windowChanged()), this, SLOT(setup_window()));
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
  m_itemEnabled = i ? i->isEnabled() : true;
}

void ItemTracker::update_window_properties() {
  auto w = m_window.value();
  m_windowActived = w ? w->isActive() : true;
}

QOOL_NS_END
