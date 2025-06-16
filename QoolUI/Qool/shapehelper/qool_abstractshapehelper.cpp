#include "qool_abstractshapehelper.h"

#include "qoolcommon/debug.hpp"

#include <QSizeF>

QOOL_NS_BEGIN

AbstractShapeHelper::AbstractShapeHelper(QObject* parent)
  : QObject { parent } {
  resetSizeBindings();
  connect(
    this, SIGNAL(targetChanged()), this, SLOT(resetSizeBindings()));

  m_shortEdge.setBinding(
    [&] { return qMin(m_width.value(), m_height.value()); });
  m_longEdge.setBinding(
    [&] { return qMax(m_width.value(), m_height.value()); });
  m_widthHeightRatio.setBinding([&] {
    const auto w = m_width.value();
    const auto h = m_height.value();
    return h == 0 ? 0.0 : w / h;
  });
  m_halfWidth.setBinding([&] { return m_width.value() / 2.0; });
  m_halfHeight.setBinding([&] { return m_height.value() / 2.0; });

  QQuickItem* pTarget = qobject_cast<QQuickItem*>(this->parent());
  set_target(pTarget);
}

void AbstractShapeHelper::dumpInfo() const {
  xDebugQ << "当前形状目标：" << target();
  xDebugQ << "当前形状尺寸" << width() << "x" << height();
}

void AbstractShapeHelper::resetSizeBindings() {
  if (m_target == nullptr) {
    m_width.takeBinding();
    m_height.takeBinding();
    return;
  }
  Qt::beginPropertyUpdateGroup();
  m_width.setBinding(
    [&] { return m_target.value()->bindableWidth().value(); });
  m_height.setBinding(
    [&] { return m_target.value()->bindableHeight().value(); });
  Qt::endPropertyUpdateGroup();
}

QOOL_NS_END
