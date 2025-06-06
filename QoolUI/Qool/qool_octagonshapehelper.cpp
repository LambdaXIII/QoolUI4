#include "qool_octagonshapehelper.h"

#include "qoolcommon/number_utils.hpp"

QOOL_NS_BEGIN

void OctagonShapeHelper::updateTLCorner() {
  const qreal cut_size =
    NumberUtils::positive_gate(m_cutSizeTL.value());
  Qt::beginPropertyUpdateGroup();
  m_extTLx.setValue(cut_size);
  m_extTLy.setValue(0);
  m_extLTx.setValue(0);
  m_extLTy.setValue(cut_size);
  Qt::endPropertyUpdateGroup();
}

void OctagonShapeHelper::updateTRCorner() {
  const qreal cut_size =
    NumberUtils::positive_gate(m_cutSizeTR.value());
  const qreal w = width();
  Qt::beginPropertyUpdateGroup();
  m_extTRx.setValue(w - cut_size);
  m_extTRy.setValue(0);
  m_extRTx.setValue(w);
  m_extRTy.setValue(cut_size);
  Qt::endPropertyUpdateGroup();
}

void OctagonShapeHelper::updateBLCorner() {
  const qreal cut_size =
    NumberUtils::positive_gate(m_cutSizeBL.value());
  const qreal h = height();
  Qt::beginPropertyUpdateGroup();
  m_extBLx.setValue(cut_size);
  m_extBLy.setValue(h);
  m_extLBx.setValue(0);
  m_extLBy.setValue(h - cut_size);
  Qt::endPropertyUpdateGroup();
}

void OctagonShapeHelper::updateBRCorner() {
  const qreal cut_size =
    NumberUtils::positive_gate(m_cutSizeBR.value());
  const qreal w = width();
  const qreal h = height();
  Qt::beginPropertyUpdateGroup();
  m_extBRx.setValue(w - cut_size);
  m_extBRy.setValue(h);
  m_extRBx.setValue(w);
  m_extRBy.setValue(h - cut_size);
  Qt::endPropertyUpdateGroup();
}

OctagonShapeHelper::OctagonShapeHelper(QObject* parent)
  : ShapeHelperBasic { parent } {
  QOOL_BINDABLE_PROPERTY_INIT_VALUE(cutSizeTL, 0);
  QOOL_BINDABLE_PROPERTY_INIT_VALUE(cutSizeTR, 0);
  QOOL_BINDABLE_PROPERTY_INIT_VALUE(cutSizeBL, 0);
  QOOL_BINDABLE_PROPERTY_INIT_VALUE(cutSizeBR, 0);

  // 绑定每个点的zobn坐标
#define PXY(_N_)                                                       \
  QOOL_BINDABLE_PROPERTY_INIT_BINDING(ext##_N_, [&] {                  \
    return QPointF(m_ext##_N_##x.value(), m_ext##_N_##y.value());      \
  })                                                                   \
  QOOL_BINDABLE_PROPERTY_INIT_BINDING(int##_N_, [&] {                  \
    return QPointF(m_int##_N_##x.value(), m_int##_N_##y.value());      \
  })

  PXY(TL)
  PXY(LT)
  PXY(TR)
  PXY(RT)
  PXY(BL)
  PXY(LB)
  PXY(BR)
  PXY(RB)

#undef PXY

  // ext points binding

  connect(this, SIGNAL(cutSizeTLChanged), this, SLOT(updateTLCorner));
  connect(this, SIGNAL(cutSizeTRChanged), this, SLOT(updateTLCorner));
  connect(this, SIGNAL(curSizeBLChanged), this, SLOT(updateBLCorner));
  connect(this, SIGNAL(cutSizeBRChanged), this, SLOT(updateBRCorner));

  connect(this, SIGNAL(widthChanged), this, SLOT(updateTRCorner));
  connect(this, SIGNAL(widthChanged), this, SLOT(updateBRCorner));
  connect(this, SIGNAL(heightChanged), this, SIGNAL(updateBLCorner));
  connect(this, SIGNAL(heightChanged), this, SLOT(updateBRCorner));

  m_polygon.setBinding([&] {
    QList<QPointF> points;
    const QPointF start_point = m_extTL.value();
    points << start_point << m_extTR.value() << m_extRT.value()
           << m_extRB.value() << m_extBR.value() << m_extBL.value()
           << m_extLB.value() << m_extLT.value() << start_point;
    return QPolygonF(points);
  });

  // int points binding

  m_intTLx.setBinding([&] {}); // TODO:unfinished
}

QOOL_NS_END
