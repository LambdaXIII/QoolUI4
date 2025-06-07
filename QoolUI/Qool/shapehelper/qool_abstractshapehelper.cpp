#include "qool_abstractshapehelper.h"

#include <QSizeF>

QOOL_NS_BEGIN

AbstractShapeHelper::AbstractShapeHelper(QObject* parent)
  : QObject { parent } {
  QQuickItem* pTarget = qobject_cast<QQuickItem*>(parent);
  set_target(pTarget);

  connect(this, SIGNAL(widthChanged), this, SIGNAL(sizeChanged));
  connect(this, SIGNAL(heightChanged), this, SIGNAL(sizeChanged));
}

QQuickItem* AbstractShapeHelper::target() const {
  return m_target;
}

void AbstractShapeHelper::set_target(QQuickItem* new_target) {
  if (m_target == new_target)
    return;
  const auto old_size = size();
  if (m_target)
    disconnect(m_target);
  m_target = new_target;
  const auto new_size = size();
  if (old_size.width() != new_size.width())
    emit widthChanged();
  if (old_size.height() != new_size.height())
    emit heightChanged();

  connect(m_target, SIGNAL(widthChanged), this, SIGNAL(widthChanged));
  connect(m_target, SIGNAL(heightChanged), this, SIGNAL(heightChanged));
}

qreal AbstractShapeHelper::width() const {
  return m_target ? m_target->width() : m_internalSize.width();
}

void AbstractShapeHelper::set_width(const qreal& new_width) {
  const qreal old = width();
  m_internalSize.setWidth(new_width);
  if (m_target || old == new_width)
    return;
  emit widthChanged();
}

qreal AbstractShapeHelper::height() const {
  return m_target ? m_target->height() : m_internalSize.height();
}

void AbstractShapeHelper::set_height(const qreal& new_height) {
  const qreal old = height();
  m_internalSize.setHeight(new_height);
  if (m_target || old == new_height)
    return;
  emit heightChanged();
}

QSizeF AbstractShapeHelper::size() const {
  return m_target ? m_target->size() : m_internalSize;
}

void AbstractShapeHelper::set_size(const QSizeF& new_size) {
  Qt::beginPropertyUpdateGroup();
  set_width(new_size.width());
  set_height(new_size.height());
  Qt::endPropertyUpdateGroup();
}

QOOL_NS_END
