#ifndef QOOL_SHAPEHELPERGADGET_H
#define QOOL_SHAPEHELPERGADGET_H

#include "qool_shapehelper.h"
#include "qoolcommon/bindable_property_macros_for_qobject.hpp"
#include "qoolns.hpp"

#include <QObject>
#include <QQmlEngine>

QOOL_NS_BEGIN

class ShapeHelperGadget: public QObject {
  Q_OBJECT
  QML_ELEMENT
  QML_UNCREATABLE("This is a virtual class for shapehelper gadgets.")
public:
  explicit ShapeHelperGadget(QObject* parent = nullptr);
  virtual ~ShapeHelperGadget() = default;

  QOOL_PROPERTY_WRITABLE_FOR_QOBJECT_BINDABLE(
    ShapeHelperGadget, ShapeHelper*, shapeHelper)
  QOOL_PROPERTY_WRITABLE_FOR_QOBJECT_BINDABLE(
    ShapeHelperGadget, QQuickItem*, shapeTarget)
  QOOL_PROPERTY_READONLY_FOR_QOBJECT_BINDABLE(
    ShapeHelperGadget, qreal, targetWidth)
  QOOL_PROPERTY_READONLY_FOR_QOBJECT_BINDABLE(
    ShapeHelperGadget, qreal, targetHeight)
  QOOL_PROPERTY_READONLY_FOR_QOBJECT_BINDABLE(
    ShapeHelperGadget, QSizeF, targetSize)
};

QOOL_NS_END

#endif // QOOL_SHAPEHELPERGADGET_H
