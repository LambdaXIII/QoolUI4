#include "qool_octagoncontainmentmasker.h"

QOOL_NS_BEGIN

OctagonContainmentMasker::OctagonContainmentMasker(QQuickItem* parent)
  : QQuickItem { parent } {
  setVisible(false);
}

bool OctagonContainmentMasker::contains(const QPointF& point) const {
  const QPointF global_p = mapFromItem(parentItem(), point);
  if (m_shapeHelper) {
    return m_shapeHelper->contains(
      mapToItem(m_shapeHelper->target(), global_p));
  }

  if (parentItem())
    return parentItem()->contains(mapToItem(parentItem(), point));

  return false;
}

QOOL_NS_END
