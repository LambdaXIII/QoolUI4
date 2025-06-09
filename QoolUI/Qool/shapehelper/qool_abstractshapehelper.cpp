#include "qool_abstractshapehelper.h"

#include <QSizeF>

QOOL_NS_BEGIN

AbstractShapeHelper::AbstractShapeHelper(QObject* parent)
  : QObject { parent } {
  QQuickItem* pTarget = qobject_cast<QQuickItem*>(this->parent());
  set_target(pTarget);

  resetSizeBindings();

  connect(
    this, SIGNAL(targetChanged()), this, SLOT(resetSizeBindings()));
}

void AbstractShapeHelper::resetSizeBindings() {
  if (m_target == nullptr)
    return;
  Qt::beginPropertyUpdateGroup();
  m_width.setBinding(
    [&] { return m_target.value()->bindableWidth().value(); });
  m_height.setBinding(
    [&] { return m_target.value()->bindableHeight().value(); });
  Qt::endPropertyUpdateGroup();
}

QOOL_NS_END
