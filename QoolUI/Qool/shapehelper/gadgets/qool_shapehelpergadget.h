#ifndef QOOL_SHAPEHELPERGADGET_H
#define QOOL_SHAPEHELPERGADGET_H

#include "qool_shapehelper.h"
#include "qoolcommon/qobject_property_macros.hpp"
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

  QBINDABLE_WRITABLE_PROPERTY(
    ShapeHelperGadget, ShapeHelper*, shapeHelper)
  QBINDABLE_WRITABLE_PROPERTY(
    ShapeHelperGadget, QQuickItem*, shapeTarget)
  QBINDABLE_READONLY_PROPERTY(
    ShapeHelperGadget, qreal, targetWidth)
  QBINDABLE_READONLY_PROPERTY(
    ShapeHelperGadget, qreal, targetHeight)
  QBINDABLE_READONLY_PROPERTY(
    ShapeHelperGadget, QSizeF, targetSize)
};

QOOL_NS_END

#endif // QOOL_SHAPEHELPERGADGET_H
