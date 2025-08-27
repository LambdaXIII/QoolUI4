#ifndef QOOL_SPACEHELPER_H
#define QOOL_SPACEHELPER_H

#include "qool_smartobj.h"
#include "qoolcommon/qbindable_property_macros.hpp"
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

  QBINDABLE_WRITABLE_PROPERTY(SpaceHelper, qreal, width)
  QBINDABLE_WRITABLE_PROPERTY(
    SpaceHelper, qreal, height)

  QBINDABLE_WRITABLE_PROPERTY(
    SpaceHelper, qreal, topPadding)
  QBINDABLE_WRITABLE_PROPERTY(
    SpaceHelper, qreal, bottomPadding)
  QBINDABLE_WRITABLE_PROPERTY(
    SpaceHelper, qreal, leftPadding)
  QBINDABLE_WRITABLE_PROPERTY(
    SpaceHelper, qreal, rightPadding)
  QBINDABLE_WRITABLE_PROPERTY_DECLARE(SpaceHelper, qreal, padding)

  QBINDABLE_WRITABLE_PROPERTY(
    SpaceHelper, qreal, topInset)
  QBINDABLE_WRITABLE_PROPERTY(
    SpaceHelper, qreal, bottomInset)
  QBINDABLE_WRITABLE_PROPERTY(
    SpaceHelper, qreal, leftInset)
  QBINDABLE_WRITABLE_PROPERTY(
    SpaceHelper, qreal, rightInset)
  QBINDABLE_WRITABLE_PROPERTY_DECLARE(SpaceHelper, qreal, inset)

  QBINDABLE_WRITABLE_PROPERTY(
    SpaceHelper, qreal, topMargin)
  QBINDABLE_WRITABLE_PROPERTY(
    SpaceHelper, qreal, bottomMargin)
  QBINDABLE_WRITABLE_PROPERTY(
    SpaceHelper, qreal, leftMargin)
  QBINDABLE_WRITABLE_PROPERTY(
    SpaceHelper, qreal, rightMargin)
  QBINDABLE_WRITABLE_PROPERTY_DECLARE(SpaceHelper, qreal, margin)

  QBINDABLE_READONLY_PROPERTY(
    SpaceHelper, qreal, contentWidth)
  QBINDABLE_READONLY_PROPERTY(
    SpaceHelper, qreal, contentHeight)
  QBINDABLE_READONLY_PROPERTY(
    SpaceHelper, qreal, backgroundWidth)
  QBINDABLE_READONLY_PROPERTY(
    SpaceHelper, qreal, backgroundHeight)
  QBINDABLE_READONLY_PROPERTY(
    SpaceHelper, qreal, marginWidth)
  QBINDABLE_READONLY_PROPERTY(
    SpaceHelper, qreal, marginHeight)

  QBINDABLE_READONLY_PROPERTY(
    SpaceHelper, QRectF, contentRect)
  QBINDABLE_READONLY_PROPERTY(
    SpaceHelper, QRectF, backgroundRect)
  QBINDABLE_READONLY_PROPERTY(
    SpaceHelper, QRectF, marginRect)
  QBINDABLE_READONLY_PROPERTY(SpaceHelper, QRectF, rect)
};

QOOL_NS_END

#endif // QOOL_SPACEHELPER_H
