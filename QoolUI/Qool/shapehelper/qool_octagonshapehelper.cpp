#include "qool_octagonshapehelper.h"

#include <QDebug>

QOOL_NS_BEGIN

OctagonShapeHelper::OctagonShapeHelper(QObject* parent)
  : AbstractShapeHelper { parent } {
  m_settings.setValue(new OctagonSettings(this));

  // 绑定安全参考值
  m_safeBorderWidth.setBinding([&] {
    return qMax(
      0.0, bindable_settings().value()->bindable_borderWidth().value());
  });

  m_safeInternalLeftBorder.setBinding([&] {
    const qreal border = m_safeBorderWidth.value();
    const qreal width = bindable_width().value();
    return qMin(border, width * 0.5);
  });

  m_safeInternalRightBorder.setBinding([&] {
    return bindable_width().value() - m_safeInternalLeftBorder.value();
  });

  m_safeInternalTopBorder.setBinding([&] {
    const qreal border = m_safeBorderWidth.value();
    const qreal height = bindable_height().value();
    return qMin(border, height * 0.5);
  });

  m_safeInternalBottomBorder.setBinding([&] {
    return bindable_height().value() - m_safeInternalTopBorder.value();
  });

  m_shortEdgeLength.setBinding([&] {
    return qMin(bindable_width().value(), bindable_height().value());
  });

  m_safeCutSizeTL.setBinding([&] {
    const qreal x =
      bindable_settings().value()->bindable_cutSizeTL().value();
    return qBound(0.0, x, m_shortEdgeLength.value());
  });

  m_safeCutSizeTR.setBinding([&] {
    const qreal x =
      bindable_settings().value()->bindable_cutSizeTR().value();
    const qreal max = qMin(m_shortEdgeLength.value(),
      bindable_width().value() - m_safeCutSizeTL.value());
    return qBound(0.0, x, max);
  });
  m_safeCutSizeBL.setBinding([&] {
    const qreal x =
      bindable_settings().value()->bindable_cutSizeBL().value();
    const qreal max = qMin(m_shortEdgeLength.value(),
      bindable_height().value() - m_safeCutSizeTL.value());
    return qBound(0.0, x, max);
  });
  m_safeCutSizeBR.setBinding([&] {
    const qreal x =
      bindable_settings().value()->bindable_cutSizeBR().value();
    const qreal max = std::max({ m_shortEdgeLength.value(),
      bindable_width().value() - m_safeCutSizeBL.value(),
      bindable_height().value() - m_safeCutSizeTR.value() });
    return qBound(0.0, x, max);
  });

  // 计算外部点的坐标
  m_externalTLx.setBinding([&] { return m_safeCutSizeTL.value(); });
  m_externalTLy.setValue(0);
  m_externalTRx.setBinding(
    [&] { return bindable_width().value() - m_safeCutSizeTR.value(); });
  m_externalTRy.setValue(0);

  m_externalRTx.setBinding([&] { return bindable_width().value(); });
  m_externalRTy.setBinding([&] { return m_safeCutSizeTR.value(); });
  m_externalRBx.setBinding([&] { return bindable_width().value(); });
  m_externalRBy.setBinding([&] {
    return bindable_height().value() - m_safeCutSizeBR.value();
  });

  m_externalBLx.setBinding([&] { return m_safeCutSizeBL.value(); });
  m_externalBLy.setBinding([&] { return bindable_height().value(); });
  m_externalBRx.setBinding(
    [&] { return bindable_width().value() - m_safeCutSizeBR.value(); });
  m_externalBRy.setBinding([&] { return bindable_height().value(); });

  m_externalLTx.setValue(0);
  m_externalLTy.setBinding([&] { return m_safeCutSizeTL.value(); });
  m_externalLBx.setValue(0);
  m_externalLBy.setBinding([&] {
    return bindable_height().value() - m_safeCutSizeBL.value();
  });

  // TODO: 计算内部点的位置
  // TODO: 绑定多边形变量

  // 合并点坐标
#define CONNECT_POINT_XY(_N_)                                          \
  m_external##_N_.setBinding([&] {                                     \
    return QPointF(                                                    \
      m_external##_N_##x.value(), m_external##_N_##y.value());         \
  });                                                                  \
  m_internal##_N_.setBinding([&] {                                     \
    return QPointF(                                                    \
      m_internal##_N_##x.value(), m_internal##_N_##y.value());         \
  });

  CONNECT_POINT_XY(TL)
  CONNECT_POINT_XY(TR)
  CONNECT_POINT_XY(BL)
  CONNECT_POINT_XY(BR)
  CONNECT_POINT_XY(LT)
  CONNECT_POINT_XY(LB)
  CONNECT_POINT_XY(RT)
  CONNECT_POINT_XY(RB)

#undef CONNECT_POINT_XY
}

void OctagonShapeHelper::dumpPoints() const {
  qDebug() << "目标对象" << target();
  qDebug() << "形状尺寸" << width() << "x" << height();
  qDebug() << "外部点坐标" << externalPoints();
}

QList<QPointF> OctagonShapeHelper::externalPoints() const {
  return { m_externalTL.value(), m_externalTR.value(),
    m_externalRT.value(), m_externalRB.value(), m_externalBR.value(),
    m_externalBL.value(), m_externalLB.value(), m_externalLT.value() };
}

QList<QPointF> OctagonShapeHelper::internalPoints() const {
  return { m_internalTL.value(), m_internalTR.value(),
    m_internalRT.value(), m_internalRB.value(), m_internalBR.value(),
    m_internalBL.value(), m_internalLB.value(), m_internalLT.value() };
}

QOOL_NS_END
