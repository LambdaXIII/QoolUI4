#include "qool_octagonshapehelper.h"

#include "qoolcommon/debug.hpp"

#include <cmath>

QOOL_NS_BEGIN

OctagonShapeHelper::OctagonShapeHelper(QObject* parent)
  : AbstractShapeHelper { parent } {
  m_settings.setValue(new OctagonSettings(this));

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

  // 绑定安全参考值
  m_safeBorderWidth.setBinding([&] {
    return qMax(
      0.0, bindable_settings().value()->bindable_borderWidth().value());
  });

  m_shortEdgeLength.setBinding([&] {
    return qMin(bindable_width().value(), bindable_height().value());
  });

  m_safeTL.setBinding([&] {
    const qreal x =
      bindable_settings().value()->bindable_cutSizeTL().value();
    return qBound(0.0, x, m_shortEdgeLength.value());
  });

  m_safeTR.setBinding([&] {
    const qreal x =
      bindable_settings().value()->bindable_cutSizeTR().value();
    const qreal max = qMin(m_shortEdgeLength.value(),
      bindable_width().value() - m_safeTL.value());
    return qBound(0.0, x, max);
  });
  m_safeBL.setBinding([&] {
    const qreal x =
      bindable_settings().value()->bindable_cutSizeBL().value();
    const qreal max = qMin(m_shortEdgeLength.value(),
      bindable_height().value() - m_safeTL.value());
    return qBound(0.0, x, max);
  });
  m_safeBR.setBinding([&] {
    const qreal x =
      bindable_settings().value()->bindable_cutSizeBR().value();
    const qreal max = std::max({ m_shortEdgeLength.value(),
      bindable_width().value() - m_safeBL.value(),
      bindable_height().value() - m_safeTR.value() });
    return qBound(0.0, x, max);
  });

  // 计算外部点的坐标
  m_externalTLx.setBinding([&] { return m_safeTL.value(); });
  m_externalTLy.setValue(0);
  m_externalTRx.setBinding(
    [&] { return bindable_width().value() - m_safeTR.value(); });
  m_externalTRy.setValue(0);

  m_externalRTx.setBinding([&] { return bindable_width().value(); });
  m_externalRTy.setBinding([&] { return m_safeTR.value(); });
  m_externalRBx.setBinding([&] { return bindable_width().value(); });
  m_externalRBy.setBinding(
    [&] { return bindable_height().value() - m_safeBR.value(); });

  m_externalBLx.setBinding([&] { return m_safeBL.value(); });
  m_externalBLy.setBinding([&] { return bindable_height().value(); });
  m_externalBRx.setBinding(
    [&] { return bindable_width().value() - m_safeBR.value(); });
  m_externalBRy.setBinding([&] { return bindable_height().value(); });

  m_externalLTx.setValue(0);
  m_externalLTy.setBinding([&] { return m_safeTL.value(); });
  m_externalLBx.setValue(0);
  m_externalLBy.setBinding(
    [&] { return bindable_height().value() - m_safeBL.value(); });

  // 计算内部点的位置

  m_internalDistance.setBinding([&] {
    // 根据三角函数计算微缩距离
    const qreal border = m_safeBorderWidth.value();
    if (border <= 0)
      return 0.0;
    static const qreal PI { std::acos(-1) };
    static const qreal _tan = std::tan(22.5 * PI / 180.0);
    qreal result = border * _tan;
    return qMax(result, 1.0);
  });

#define BDR m_safeBorderWidth.value()
#define DST m_internalDistance.value()
#define TOP BDR
#define BTM bindable_height().value() - BDR
#define LFT BDR
#define RIT bindable_width().value() - BDR

  m_internalTLx.setBinding(
    [&] { return qMax(LFT, m_externalTLx.value() + DST); });
  m_internalTLy.setBinding(
    [&] { return qMax(TOP, m_externalTLy.value() + BDR); });

  m_internalTRx.setBinding(
    [&] { return qMin(RIT, m_externalTRx.value() - DST); });
  m_internalTRy.setBinding(
    [&] { return qMax(TOP, m_externalTRy.value() + BDR); });

  m_internalRTx.setBinding(
    [&] { return qMin(RIT, m_externalRTx.value() - BDR); });
  m_internalRTy.setBinding(
    [&] { return qMax(TOP, m_externalRTy.value() + DST); });

  m_internalRBx.setBinding(
    [&] { return qMin(RIT, m_externalRBx.value() - BDR); });
  m_internalRBy.setBinding(
    [&] { return qMin(BTM, m_externalRBy.value() - DST); });

  m_internalBRx.setBinding(
    [&] { return qMin(RIT, m_externalBRx.value() - DST); });
  m_internalBRy.setBinding(
    [&] { return qMin(BTM, m_externalBRy.value() - BDR); });

  m_internalBLx.setBinding(
    [&] { return qMax(LFT, m_externalBLx.value() + DST); });
  m_internalBLy.setBinding(
    [&] { return qMin(BTM, m_externalBLy.value() - BDR); });

  m_internalLBx.setBinding(
    [&] { return qMax(LFT, m_externalLBx.value() + BDR); });
  m_internalLBy.setBinding(
    [&] { return qMin(BTM, m_externalLBy.value() - DST); });

  m_internalLTx.setBinding(
    [&] { return qMax(LFT, m_externalLTx.value() + BDR); });
  m_internalLTy.setBinding(
    [&] { return qMax(TOP, m_externalLTy.value() + DST); });

#undef TOP
#undef LFT
#undef BTM
#undef RIT
#undef BDR
#undef DST

  // 绑定多边形变量
  m_internalPolygon.setBinding([&] {
    QList<QPointF> pts;
    pts << m_internalTL << m_internalTR << m_internalRT << m_internalRB
        << m_internalBR << m_internalBL << m_internalLB << m_internalLT
        << m_internalTL;
    return QPolygonF(pts);
  });
  m_externalPolygon.setBinding([&] {
    QList<QPointF> pts;
    pts << m_externalTL << m_externalTR << m_externalRT << m_externalRB
        << m_externalBR << m_externalBL << m_externalLB << m_externalLT
        << m_externalTL;
    return QPolygonF(pts);
  });
}

void OctagonShapeHelper::dumpInfo() const {
  AbstractShapeHelper::dumpInfo();
  xDebugQ << "设定信息：";
  m_settings.value()->dumpInfo();

  const auto format_point = [](const QPointF& p) {
    return QString(
      "[" xDBGGreen "%1" xDBGReset "," xDBGGreen "%2" xDBGReset "]")
      .arg(p.x(), 3, 'g', -1, u' ')
      .arg(p.y(), 3, 'g', -1, u' ');
  };

  const auto format_points = [&](const QList<QPointF>& points) {
    QStringList ss;
    std::transform(points.begin(), points.end(), std::back_inserter(ss),
      format_point);
    return ss.join(' ');
  };

  xDebugQ << "外部路径点：" << format_points(externalPoints());
  xDebugQ << "内部路径点：" << format_points(internalPoints());
}

bool OctagonShapeHelper::contains(const QPointF& point) const {
  const auto x = point.x();
  const auto y = point.y();
  const QRectF boundingRect { 0, 0, m_width, m_height };
  if (! boundingRect.contains(point))
    return false;
  if (x + y < m_safeTL)
    return false;
  if (m_width - x + y < m_safeTR)
    return false;
  if (x + m_height - y < m_safeTL)
    return false;
  if (m_width - x + m_height - y < m_safeBR)
    return false;
  return true;
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
