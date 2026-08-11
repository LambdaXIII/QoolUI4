#ifndef QOOL_SHAPEGADGET_CRYSTAL_H
#define QOOL_SHAPEGADGET_CRYSTAL_H

#include "qool_shapecontrol_gadget.h"
#include "qoolcommon/macro_foreach.hpp"
#include "qoolcommon/qbindable_property_macros.hpp"
#include "qoolns.hpp"
#include <QObject>
#include <QQmlEngine>

QOOL_NS_BEGIN

class CrystalGadget : public ShapeControlGadget {
  Q_OBJECT
  QML_ELEMENT
  Q_CLASSINFO("ShapeControlGadgetName", "Crystal")

public:
  explicit CrystalGadget(QObject* parent = nullptr);

  bool contains(const QPointF&) const override;

private:
  QBINDABLE_WRITABLE_PROPERTY(CrystalGadget, qreal, x, FINAL)
  QBINDABLE_WRITABLE_PROPERTY(CrystalGadget, qreal, y, FINAL)
  QBINDABLE_WRITABLE_PROPERTY(CrystalGadget, qreal, width, FINAL)
  QBINDABLE_WRITABLE_PROPERTY(CrystalGadget, qreal, height, FINAL)

  /*! \qmlproperty qreal 四角切角（等腰直角三角形直角边 = shortEdge/2）——八点统一基准。 */
  QBINDABLE_READONLY_PROPERTY(CrystalGadget, qreal, cutSize)
  /*! \qmlproperty qreal 半宽（width/2 中间量——顶/底中点复用）。 */
  QBINDABLE_READONLY_PROPERTY(CrystalGadget, qreal, halfWidth)
  /*! \qmlproperty qreal 半高（height/2 中间量——备用，含竖直形态）。 */
  QBINDABLE_READONLY_PROPERTY(CrystalGadget, qreal, halfHeight)

#define DECL_POINT(_N_)                                      \
  QBINDABLE_READONLY_PROPERTY(CrystalGadget, QPointF, _N_)   \
  QBINDABLE_READONLY_PROPERTY(CrystalGadget, qreal, _N_##x)  \
  QBINDABLE_READONLY_PROPERTY(CrystalGadget, qreal, _N_##y)

  // 八点模型（四角排除域的顶点——统一覆盖宽六边形/菱形/瘦六边形）：
  // TL/TC/TR 顶边三点、RT/RB 右边两端、BC 底边中点、LB/LT 左边两端。
  // 点绑定引用中间量（cutSize/halfWidth 等），不裸算 w/2（按需触发）。
  QOOL_FOREACH_8(DECL_POINT, TL, TC, TR, RT, RB, BC, LB, LT)
#undef DECL_POINT
};

QOOL_NS_END

#endif // QOOL_SHAPEGADGET_CRYSTAL_H
