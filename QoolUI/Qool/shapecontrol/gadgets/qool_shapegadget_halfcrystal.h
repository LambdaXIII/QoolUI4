#ifndef QOOL_SHAPEGADGET_HALFCRYSTAL_H
#define QOOL_SHAPEGADGET_HALFCRYSTAL_H

#include "qool_shapecontrol_gadget.h"
#include "qool_shapegadget_rect.h"

#include "qoolcommon/qbindable_property_macros.hpp"
#include "qoolns.hpp"
#include <QObject>
#include <QQmlEngine>

QOOL_NS_BEGIN

class HalfCrystalGadget : public ShapeControlGadget {
  Q_OBJECT
  QML_ELEMENT
  Q_CLASSINFO("ShapeControlGadgetName", "HalfCrystal")

public:
  explicit HalfCrystalGadget(QObject* parent = nullptr);

  bool contains(const QPointF&) const override;

private:
  // 掩码几何源（HalfCrystal 的画布 RectGadget gB）+ 方向——contains 判定
  // 输入；挂载于 ShapeControl 下但不消费其几何（几何来自 geometrySource）
  QBINDABLE_WRITABLE_PROPERTY(HalfCrystalGadget, RectGadget*, geometrySource,
      FINAL)
  /*! \qmlproperty int direction 方向（QoolLiterals::Directions）——
      N/S/W/E 为半区粗判，其余值为整正方形粗判。 */
  QBINDABLE_WRITABLE_PROPERTY(HalfCrystalGadget, int, direction, FINAL)
};

QOOL_NS_END

#endif // QOOL_SHAPEGADGET_HALFCRYSTAL_H
