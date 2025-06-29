#ifndef QOOL_SPACEHELPER_H
#define QOOL_SPACEHELPER_H

#include "qool_smartobj.h"
#include "qoolcommon/bindable_property_macros_for_qobject.hpp"
#include "qoolns.hpp"

#include <QObject>
#include <QQmlEngine>
#include <QRectF>

QOOL_NS_BEGIN

class SpaceHelper: public SmartObject {
  Q_OBJECT
  QML_ELEMENT

public:
  explicit SpaceHelper(QObject* parent = nullptr);

  Q_INVOKABLE void setPaddings(
    qreal top, qreal right, qreal bottom, qreal left);
  Q_INVOKABLE void setInsets(
    qreal top, qreal right, qreal bottom, qreal left);
  Q_INVOKABLE void setMargins(
    qreal top, qreal right, qreal bottom, qreal left);

  QOOL_PROPERTY_WRITABLE_FOR_QOBJECT_BINDABLE(SpaceHelper, qreal, width)
  QOOL_PROPERTY_WRITABLE_FOR_QOBJECT_BINDABLE(
    SpaceHelper, qreal, height)

  QOOL_PROPERTY_WRITABLE_FOR_QOBJECT_BINDABLE(
    SpaceHelper, qreal, topPadding)
  QOOL_PROPERTY_WRITABLE_FOR_QOBJECT_BINDABLE(
    SpaceHelper, qreal, bottomPadding)
  QOOL_PROPERTY_WRITABLE_FOR_QOBJECT_BINDABLE(
    SpaceHelper, qreal, leftPadding)
  QOOL_PROPERTY_WRITABLE_FOR_QOBJECT_BINDABLE(
    SpaceHelper, qreal, rightPadding)
  QOOL_PROPERTY_WRITABLE_FOR_QOBJECT_BINDABLE_DECL(
    SpaceHelper, qreal, padding)

  QOOL_PROPERTY_WRITABLE_FOR_QOBJECT_BINDABLE(
    SpaceHelper, qreal, topInset)
  QOOL_PROPERTY_WRITABLE_FOR_QOBJECT_BINDABLE(
    SpaceHelper, qreal, bottomInset)
  QOOL_PROPERTY_WRITABLE_FOR_QOBJECT_BINDABLE(
    SpaceHelper, qreal, leftInset)
  QOOL_PROPERTY_WRITABLE_FOR_QOBJECT_BINDABLE(
    SpaceHelper, qreal, rightInset)
  QOOL_PROPERTY_WRITABLE_FOR_QOBJECT_BINDABLE_DECL(
    SpaceHelper, qreal, inset)

  QOOL_PROPERTY_WRITABLE_FOR_QOBJECT_BINDABLE(
    SpaceHelper, qreal, topMargin)
  QOOL_PROPERTY_WRITABLE_FOR_QOBJECT_BINDABLE(
    SpaceHelper, qreal, bottomMargin)
  QOOL_PROPERTY_WRITABLE_FOR_QOBJECT_BINDABLE(
    SpaceHelper, qreal, leftMargin)
  QOOL_PROPERTY_WRITABLE_FOR_QOBJECT_BINDABLE(
    SpaceHelper, qreal, rightMargin)
  QOOL_PROPERTY_WRITABLE_FOR_QOBJECT_BINDABLE_DECL(
    SpaceHelper, qreal, margin)

  QOOL_PROPERTY_READONLY_FOR_QOBJECT_BINDABLE(
    SpaceHelper, qreal, contentWidth)
  QOOL_PROPERTY_READONLY_FOR_QOBJECT_BINDABLE(
    SpaceHelper, qreal, contentHeight)
  QOOL_PROPERTY_READONLY_FOR_QOBJECT_BINDABLE(
    SpaceHelper, qreal, backgroundWidth)
  QOOL_PROPERTY_READONLY_FOR_QOBJECT_BINDABLE(
    SpaceHelper, qreal, backgroundHeight)
  QOOL_PROPERTY_READONLY_FOR_QOBJECT_BINDABLE(
    SpaceHelper, qreal, marginWidth)
  QOOL_PROPERTY_READONLY_FOR_QOBJECT_BINDABLE(
    SpaceHelper, qreal, marginHeight)

  QOOL_PROPERTY_READONLY_FOR_QOBJECT_BINDABLE(
    SpaceHelper, QRectF, contentRect)
  QOOL_PROPERTY_READONLY_FOR_QOBJECT_BINDABLE(
    SpaceHelper, QRectF, backgroundRect)
  QOOL_PROPERTY_READONLY_FOR_QOBJECT_BINDABLE(
    SpaceHelper, QRectF, marginRect)
  QOOL_PROPERTY_READONLY_FOR_QOBJECT_BINDABLE(SpaceHelper, QRectF, rect)
};

QOOL_NS_END

#endif // QOOL_SPACEHELPER_H
