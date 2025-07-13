#include "qool_octagonshapehelper.h"

#include "qoolcommon/debug.hpp"
#include "qoolcommon/math.hpp"

#include <cmath>

QOOL_NS_BEGIN

OctagonShapeHelper::OctagonShapeHelper(QObject* parent)
  : AbstractShapeHelper { parent }
  , m_settings { new OctagonSettings(this) } {
  __setup_reference_values();
  __setup_ext_points();
  __setup_int_points();
  __connect_points();

  m_offsetX.setBinding([&] {
    return bindable_settings().value()->bindable_offsetX().value();
  });
  m_offsetY.setBinding([&] {
    return bindable_settings().value()->bindable_offsetY().value();
  });

  m_intOffsetX.setBinding([&] {
    return bindable_settings().value()->bindable_intOffsetX().value();
  });
  m_intOffsetY.setBinding([&] {
    return bindable_settings().value()->bindable_intOffsetY().value();
  });

  m_intPoints.setBinding([&] {
    return QList<QPointF> { m_intTL.value(), m_intTR.value(),
      m_intRT.value(), m_intRB.value(), m_intBR.value(),
      m_intBL.value(), m_intLB.value(), m_intLT.value() };
  });

  m_extPoints.setBinding([&] {
    return QList<QPointF> { m_extTL.value(), m_extTR.value(),
      m_extRT.value(), m_extRB.value(), m_extBR.value(),
      m_extBL.value(), m_extLB.value(), m_extLT.value() };
  });

  m_intPolygon.setBinding([&] {
    auto points = m_intPoints.value();
    auto start_point = points.first();
    points.append(start_point);
    return QPolygonF(points);
  });

  m_extPolygon.setBinding([&] {
    auto points = m_extPoints.value();
    auto start_point = points.first();
    points.append(start_point);
    return QPolygonF(points);
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

  xDebugQ << xDBGYellow << "CutSizes" << xDBGCyan << safeTL()
          << safeTR() << safeBL() << safeBR() << xDBGReset;
  xDebugQ << xDBGYellow << "BorderWidth" << xDBGCyan
          << m_safeBorderWidth.value() << xDBGYellow
          << "BorderShrinkSize" << xDBGCyan
          << m_borderShrinkSize.value() << xDBGReset;
  ;

#define DEBUG_P(A)                                                     \
  xDebugQ << xDBGYellow << #A << xDBGCyan                              \
          << format_point(m_ext##A.value())                            \
          << format_point(m_int##A.value()) << xDBGReset;
  QOOL_FOREACH_8(DEBUG_P, TL, TR, RT, RB, BR, BL, LB, LT);
#undef DEBUG_P

  xDebugQ << "safe values:" << "TL" << safeTL() << "TR" << safeTR()
          << "BL" << safeBL() << "BR" << safeBR();
}

bool OctagonShapeHelper::contains(const QPointF& point) const {
  const auto x = point.x();
  const auto y = point.y();
  const bool in_bound = AbstractShapeHelper::contains(point);
  if (! in_bound)
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

void OctagonShapeHelper::__setup_reference_values() {
#define SHORT_EDGE bindable_shortEdge().value()
  m_safeTL.setBinding([&] {
    const qreal x =
      bindable_settings().value()->bindable_cutSizeTL().value();
    return math::auto_bound(0.0, x, SHORT_EDGE);
  });

  m_safeTR.setBinding([&] {
    const qreal x =
      bindable_settings().value()->bindable_cutSizeTR().value();
    const qreal max =
      qMin(SHORT_EDGE, bindable_width().value() - m_safeTL.value());
    return math::auto_bound(0.0, x, max);
  });
  m_safeBL.setBinding([&] {
    const qreal x =
      bindable_settings().value()->bindable_cutSizeBL().value();
    const qreal max =
      qMin(SHORT_EDGE, bindable_height().value() - m_safeTL.value());
    return math::auto_bound(0.0, x, max);
  });
  m_safeBR.setBinding([&] {
    const qreal x =
      bindable_settings().value()->bindable_cutSizeBR().value();
    const qreal max = std::min(
      { SHORT_EDGE, bindable_width().value() - m_safeBL.value(),
        bindable_height().value() - m_safeTR.value() });
    return math::auto_bound(0.0, x, max);
  });
#undef SHORT_EDGE

  m_safeBorderWidth.setBinding([&] {
    return qMax(
      0.0, bindable_settings().value()->bindable_borderWidth().value());
  });

  m_borderShrinkSize.setBinding([&] {
    const qreal border = m_safeBorderWidth.value();
    if (border <= 0)
      return 0.0;
    static const qreal _tan = std::tan(22.5 * M_PI / 180.0);
    return qMax(_tan * border, 1.0);
  });

} //__setup_reference_values

void OctagonShapeHelper::__connect_points() {
#define CONNECT_P(_N_)                                                 \
  m_##_N_.setBinding(                                                  \
    [&] { return QPointF(m_##_N_##x.value(), m_##_N_##y.value()); });
  QOOL_FOREACH_8(
    CONNECT_P, intTL, intTR, intLT, intLB, intRT, intRB, intBL, intBR)
  QOOL_FOREACH_8(
    CONNECT_P, extTL, extTR, extLT, extLB, extRT, extRB, extBL, extBR)
#undef CONNECT_P
}

void OctagonShapeHelper::__setup_ext_points() {
#define W bindable_width().value()
#define H bindable_height().value()
  m_extTLx.setBinding(
    [&] { return m_safeTL.value() + m_offsetX.value(); });
  m_extTLy.setBinding([&] { return 0 + m_offsetY.value(); });
  m_extTRx.setBinding(
    [&] { return W - m_safeTR.value() + m_offsetX.value(); });
  m_extTRy.setBinding([&] { return 0 + m_offsetY.value(); });

  m_extBLx.setBinding(
    [&] { return m_safeBL.value() + m_offsetX.value(); });
  m_extBLy.setBinding([&] { return H + m_offsetY.value(); });
  m_extBRx.setBinding(
    [&] { return W - m_safeBR.value() + m_offsetX.value(); });
  m_extBRy.setBinding([&] { return H + m_offsetY.value(); });

  m_extLTx.setBinding([&] { return 0 + m_offsetX.value(); });
  m_extLTy.setBinding(
    [&] { return m_safeTL.value() + m_offsetY.value(); });
  m_extLBx.setBinding([&] { return 0 + m_offsetX.value(); });
  m_extLBy.setBinding(
    [&] { return H - m_safeBL.value() + m_offsetY.value(); });

  m_extRTx.setBinding([&] { return W + m_offsetX.value(); });
  m_extRTy.setBinding(
    [&] { return m_safeTR.value() + m_offsetY.value(); });
  m_extRBx.setBinding([&] { return W + m_offsetX.value(); });
  m_extRBy.setBinding(
    [&] { return H - m_safeBR.value() + m_offsetY.value(); });
#undef W
#undef H
}

void OctagonShapeHelper::__setup_int_points() {
#define W bindable_width().value()
#define H bindable_height().value()
#define DEF_COMMON const auto border = m_safeBorderWidth.value();
#define DEF_SHRINK const auto shrink = m_borderShrinkSize.value();

#define DEF_VALUES_X                                                   \
  DEF_COMMON;                                                          \
  const auto offset = m_intOffsetX.value();

#define DEF_VALUES_Y                                                   \
  DEF_COMMON;                                                          \
  const auto offset = m_intOffsetY.value();

#define RETURN_X(V)                                                    \
  const auto __offset_x__ = m_offsetX.value();                         \
  const auto left = border + __offset_x__;                             \
  const auto right = W - border + __offset_x__;                        \
  return math::auto_bound(left, V, right) + offset;

#define RETURN_Y(V)                                                    \
  const auto __offset_y__ = m_offsetY.value();                         \
  const auto top = border + __offset_y__;                              \
  const auto bottom = H - border + __offset_y__;                       \
  return math::auto_bound(top, V, bottom) + offset;

  m_intTLx.setBinding([&] {
    DEF_VALUES_X
    DEF_SHRINK
    const auto base = m_extTLx.value();
    qreal result = (border == 0) ? base : base + shrink;
    RETURN_X(result);
  });

  m_intTLy.setBinding([&] {
    DEF_VALUES_Y
    const auto base = m_extTLy.value();
    const auto result = (border == 0) ? base : base + border;
    RETURN_Y(result)
  });
  m_intTRx.setBinding([&] {
    DEF_VALUES_X
    DEF_SHRINK
    const auto base = m_extTRx.value();
    const auto result = (border == 0) ? base : base - shrink;
    RETURN_X(result)
  });
  m_intTRy.setBinding([&] {
    DEF_VALUES_Y
    const auto base = m_extTRy.value();
    const auto result = (border == 0) ? base : base + border;
    RETURN_Y(result)
  });

  m_intBLx.setBinding([&] {
    DEF_VALUES_X
    DEF_SHRINK
    const auto base = m_extBLx.value();
    const auto result = (border == 0) ? base : base + shrink;
    RETURN_X(result);
  });
  m_intBLy.setBinding([&] {
    DEF_VALUES_Y
    const auto base = m_extBLy.value();
    const auto result = (border == 0) ? base : base - border;
    RETURN_Y(result);
  });
  m_intBRx.setBinding([&] {
    DEF_VALUES_X
    DEF_SHRINK
    const auto base = m_extBRx.value();
    const auto result = (border == 0) ? base : base - shrink;
    RETURN_X(result);
  });
  m_intBRy.setBinding([&] {
    DEF_VALUES_Y
    const auto base = m_extBRy.value();
    const auto result = (border == 0) ? base : base - border;
    RETURN_Y(result)
  });

  m_intLTx.setBinding([&] {
    DEF_VALUES_X
    const auto base = m_extLTx.value();
    const auto result = (border == 0) ? base : base + border;
    RETURN_X(result);
  });
  m_intLTy.setBinding([&] {
    DEF_VALUES_Y
    DEF_SHRINK
    const auto base = m_extLTy.value();
    const auto result = (border == 0) ? base : base + shrink;
    RETURN_Y(result)
  });
  m_intLBx.setBinding([&] {
    DEF_VALUES_X
    const auto base = m_extLBx.value();
    const auto result = (border == 0) ? base : base + border;
    RETURN_X(result)
  });
  m_intLBy.setBinding([&] {
    DEF_VALUES_Y
    DEF_SHRINK
    const auto base = m_extLBy.value();
    const auto result = (border == 0) ? base : base + shrink;
    RETURN_Y(result)
  });

  m_intRTx.setBinding([&] {
    DEF_VALUES_X
    const auto base = m_extRTx.value();
    const auto result = (border == 0) ? base : base - border;
    RETURN_X(result)
  });
  m_intRTy.setBinding([&] {
    DEF_VALUES_Y
    DEF_SHRINK
    const auto base = m_extRTy.value();
    const auto result = (border == 0) ? base : base + shrink;
    RETURN_Y(result)
  });
  m_intRBx.setBinding([&] {
    DEF_VALUES_X
    const auto base = m_extRBx.value();
    const auto result = (border == 0) ? base : base - border;
    RETURN_X(result)
  });
  m_intRBy.setBinding([&] {
    DEF_VALUES_Y
    DEF_SHRINK
    const auto base = m_extRBy.value();
    const auto result = (border == 0) ? base : base - shrink;
    RETURN_Y(result)
  });

#undef RETURN_X
#undef RETURN_Y
#undef DEF_VALUES_X
#undef DEF_VALUES_Y
#undef DEF_COMMON
#undef DEF_SHRINK
#undef H
#undef W
}

QOOL_NS_END
