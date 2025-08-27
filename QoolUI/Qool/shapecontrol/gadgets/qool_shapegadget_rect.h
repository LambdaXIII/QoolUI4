#ifndef QOOL_SHAPEGADGET_RECT_H
#define QOOL_SHAPEGADGET_RECT_H

#include "qool_shapecontrol_gadget.h"
#include "qoolcommon/macro_foreach.hpp"
#include "qoolcommon/qbindable_property_macros.hpp"
#include "qoolns.hpp"
#include <QObject>
#include <QQmlEngine>
QOOL_NS_BEGIN

class RectGadget : public ShapeControlGadget {
  Q_OBJECT
  QML_ELEMENT
  Q_CLASSINFO("ShapeControlGadgetName", "Rect")

public:
  explicit RectGadget(QObject* parent = nullptr);

private:
  QProperty<qreal> m_left, m_right, m_top, m_bottom, m_hcenter, m_vcenter;

  QBINDABLE_WRITABLE_PROPERTY(RectGadget, qreal, x, FINAL)
  QBINDABLE_WRITABLE_PROPERTY(RectGadget, qreal, y, FINAL)
  QBINDABLE_WRITABLE_PROPERTY(RectGadget, qreal, width, FINAL)
  QBINDABLE_WRITABLE_PROPERTY(RectGadget, qreal, height, FINAL)
  QBINDABLE_WRITABLE_PROPERTY_DECLARE(RectGadget, QRectF, rect, FINAL)

#define DECL(NAME)                                        \
  QBINDABLE_READONLY_PROPERTY(RectGadget, QPointF, NAME)  \
  QBINDABLE_READONLY_PROPERTY(RectGadget, qreal, NAME##X) \
  QBINDABLE_READONLY_PROPERTY(RectGadget, qreal, NAME##Y)

  QOOL_FOREACH_9(DECL, topLeft, topCenter, topRight, leftCenter, center,
      rightCenter, bottomLeft, bottomCenter, bottomRight)
#undef DECL
};

QOOL_NS_END

#endif // QOOL_SHAPEGADGET_RECT_H
