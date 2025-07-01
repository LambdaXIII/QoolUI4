#include "qool_spacehelper.h"

#include <QMutex>

QOOL_NS_BEGIN

SpaceHelper::SpaceHelper(QObject* parent)
  : SmartObject { parent } {
  QOOL_PROPERTY_BINDABLE_INIT_VALUE(width, 100)
  QOOL_PROPERTY_BINDABLE_INIT_VALUE(height, 100)

  QOOL_PROPERTY_BINDABLE_INIT_BINDING(contentWidth,
    [&] { return m_width - m_leftPadding - m_rightPadding; })
  QOOL_PROPERTY_BINDABLE_INIT_BINDING(contentHeight,
    [&] { return m_height - m_topPadding - m_bottomPadding; })
  QOOL_PROPERTY_BINDABLE_INIT_BINDING(backgroundWidth,
    [&] { return m_width - m_leftInset - m_rightInset; })
  QOOL_PROPERTY_BINDABLE_INIT_BINDING(backgroundHeight,
    [&] { return m_height - m_topInset - m_bottomInset; })
  QOOL_PROPERTY_BINDABLE_INIT_BINDING(
    marginWidth, [&] { return m_width + m_leftMargin + m_rightMargin; })
  QOOL_PROPERTY_BINDABLE_INIT_BINDING(marginHeight,
    [&] { return m_height + m_topMargin + m_bottomMargin; })
  QOOL_PROPERTY_BINDABLE_INIT_BINDING(
    rect, [&] { return QRectF(0, 0, m_width, m_height); })
  QOOL_PROPERTY_BINDABLE_INIT_BINDING(contentRect, [&] {
    return QRectF(
      m_leftPadding, m_topPadding, m_contentWidth, m_contentHeight);
  })
  QOOL_PROPERTY_BINDABLE_INIT_BINDING(backgroundRect, [&] {
    return QRectF(
      m_leftInset, m_topInset, m_backgroundWidth, m_backgroundHeight);
  })
  QOOL_PROPERTY_BINDABLE_INIT_BINDING(marginRect, [&] {
    return QRectF(
      0 - m_leftMargin, 0 - m_topMargin, m_marginWidth, m_marginHeight);
  })

  set_padding(0);
  set_inset(0);
}

void SpaceHelper::setPaddings(
  qreal top, qreal right, qreal bottom, qreal left) {
  Qt::beginPropertyUpdateGroup();
  m_topPadding = top;
  m_bottomPadding = bottom;
  m_leftPadding = left;
  m_rightPadding = right;
  Qt::endPropertyUpdateGroup();
}

void SpaceHelper::setInsets(
  qreal top, qreal right, qreal bottom, qreal left) {
  Qt::beginPropertyUpdateGroup();
  m_topInset = top;
  m_bottomInset = bottom;
  m_leftInset = left;
  m_rightInset = right;
  Qt::endPropertyUpdateGroup();
}

void SpaceHelper::setMargins(
  qreal top, qreal right, qreal bottom, qreal left) {
  Qt::beginPropertyUpdateGroup();
  m_topMargin = top;
  m_bottomMargin = bottom;
  m_leftMargin = left;
  m_rightMargin = right;
  Qt::endPropertyUpdateGroup();
}

qreal SpaceHelper::padding() const {
  return m_padding.value();
}

qreal SpaceHelper::inset() const {
  return m_inset.value();
}

qreal SpaceHelper::margin() const {
  return m_margin.value();
}

void SpaceHelper::set_padding(const qreal& value) {
  Qt::beginPropertyUpdateGroup();
  m_padding = value;
  m_topPadding = value;
  m_bottomPadding = value;
  m_leftPadding = value;
  m_rightPadding = value;
  Qt::endPropertyUpdateGroup();
}

void SpaceHelper::set_inset(const qreal& value) {
  Qt::beginPropertyUpdateGroup();
  m_inset = value;
  m_topInset = value;
  m_bottomInset = value;
  m_leftInset = value;
  m_rightInset = value;
  Qt::endPropertyUpdateGroup();
}

void SpaceHelper::set_margin(const qreal& value) {
  Qt::beginPropertyUpdateGroup();
  m_margin = value;
  m_topMargin = value;
  m_bottomMargin = value;
  m_leftMargin = value;
  m_rightMargin = value;
  Qt::endPropertyUpdateGroup();
}

QOOL_NS_END
