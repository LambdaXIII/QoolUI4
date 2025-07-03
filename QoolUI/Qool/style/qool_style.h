#ifndef QOOL_STYLE_H
#define QOOL_STYLE_H

#include "qool_stylevaluegroup.h"
#include "qool_theme_values_support.h"
#include "qoolcommon/bindable_property_macros_for_qobject.hpp"
#include "qoolcommon/property_macros_for_qobject.hpp"
#include "qoolns.hpp"

#include <QBindable>
#include <QColor>
#include <QObject>
#include <QPalette>
#include <QQmlEngine>
#include <QQuickAttachedPropertyPropagator>
#include <QQuickItem>

QOOL_NS_BEGIN

class Style: public QQuickAttachedPropertyPropagator {
  Q_OBJECT
  QML_ELEMENT
  QML_ATTACHED(QOOL_NS::Style)

public:
  explicit Style(QObject* parent = nullptr);
  ~Style() = default;

  static Style* qmlAttachedPropertyes(QObject* object);

  QVariant value(QPalette::ColorGroup, QAnyStringView key) const;
  QVariant value(QAnyStringView key) const;
  void setValue(
    QPalette::ColorGroup, QAnyStringView key, const QVariant& value);
  void setValue(QAnyStringView key, const QVariant& value);

  void inherit(Style* other);

  QOOL_PROPERTY_READONLY_FOR_QOBJECT_BINDABLE(
    Style, QPalette::ColorGroup, currentGroup)
};

QOOL_NS_END

#endif // QOOL_STYLE_H
