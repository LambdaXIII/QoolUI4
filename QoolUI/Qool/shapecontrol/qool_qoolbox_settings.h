#ifndef QOOL_QOOLBOX_SETTINGS_H
#define QOOL_QOOLBOX_SETTINGS_H

#include "qoolcommon/qbindable_property_macros.hpp"
#include "qoolns.hpp"

#include <QColor>
#include <QObject>
#include <QObjectBindableProperty>
#include <QQmlEngine>

QOOL_NS_BEGIN

class QoolBoxSettings : public QObject {
  Q_OBJECT
  QML_ELEMENT

public:
  explicit QoolBoxSettings(QObject* parent = nullptr);

  QBINDABLE_WRITABLE_PROPERTY(QoolBoxSettings, qreal, cutSizeTL)
  QBINDABLE_WRITABLE_PROPERTY(QoolBoxSettings, qreal, cutSizeTR)
  QBINDABLE_WRITABLE_PROPERTY(QoolBoxSettings, qreal, cutSizeBL)
  QBINDABLE_WRITABLE_PROPERTY(QoolBoxSettings, qreal, cutSizeBR)
  QBINDABLE_WRITABLE_PROPERTY(QoolBoxSettings, qreal, borderWidth)
  QBINDABLE_WRITABLE_PROPERTY(QoolBoxSettings, QColor, borderColor)
  QBINDABLE_WRITABLE_PROPERTY(QoolBoxSettings, QColor, fillColor)
  QBINDABLE_WRITABLE_PROPERTY(QoolBoxSettings, qreal, offsetX)
  QBINDABLE_WRITABLE_PROPERTY(QoolBoxSettings, qreal, offsetY)
  QBINDABLE_WRITABLE_PROPERTY(QoolBoxSettings, bool, curved)

  // 辅助类属性
  QBINDABLE_READONLY_PROPERTY(QoolBoxSettings, qreal, cutSpaceOnTop)
  QBINDABLE_READONLY_PROPERTY(QoolBoxSettings, qreal, cutSpaceOnBottom)
  QBINDABLE_READONLY_PROPERTY(QoolBoxSettings, qreal, cutSpaceOnLeft)
  QBINDABLE_READONLY_PROPERTY(QoolBoxSettings, qreal, cutSpaceOnRight)
};

QOOL_NS_END

#endif // QOOL_QOOLBOX_SETTINGS_H
