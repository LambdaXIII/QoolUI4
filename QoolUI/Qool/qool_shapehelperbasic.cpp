#include "qool_shapehelperbasic.h"

QOOL_NS_BEGIN

ShapeHelperBasic::ShapeHelperBasic(QObject* parent)
  : QObject { parent } {
  auto target_ptr = qobject_cast<QQuickItem*>(parent);
  set_target(target_ptr);

  connect(this, &ShapeHelperBasic::targetChanged, this, [&] {
    emit widthChanged();
    emit heightChanged();
    emit sizeChanged();
  });
}

QSizeF ShapeHelperBasic::size() const {
  if (m_target == nullptr)
    return m_internalSize;
  return m_target->size();
}

void ShapeHelperBasic::set_size(QSizeF s) {
  const auto old_size = size();
  m_internalSize = s;
  if (old_size == m_internalSize)
    return;
  emit sizeChanged();
  if (old_size.width() != s.width())
    emit widthChanged();
  if (old_size.height() != s.height())
    emit heightChanged();
}

qreal ShapeHelperBasic::width() const {
  return m_target ? m_target->width() : m_internalSize.width();
}

void ShapeHelperBasic::set_width(qreal w) {
  qreal old = width();
  m_internalSize.setWidth(w);
  if (m_target || old == w)
    return;
  emit widthChanged();
  emit sizeChanged();
}

qreal ShapeHelperBasic::height() const {
  return m_target ? m_target->height() : m_internalSize.height();
}

void ShapeHelperBasic::set_height(qreal h) {
  qreal old = height();
  m_internalSize.setHeight(h);
  if (m_target || old == h)
    return;
  emit heightChanged();
  emit sizeChanged();
}

QOOL_NS_END
