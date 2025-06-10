#include "qool_shapehelper.h"

#include "qoolcommon/debug.hpp"

QOOL_NS_BEGIN

ShapeHelper::ShapeHelper(QObject* parent)
  : AbstractShapeHelper { parent } {
  __setup_all_points();
  m_boundingCenter.setBinding([&] {
    return QPointF(
      bindable_width().value() * 0.5, bindable_height().value() * 0.5);
  });
}

void ShapeHelper::dumpInfo() const {
  QMap<QString, QPointF> points;
#define INSERT_POINT(N) points[#N] = point##N();
  QOOL_MACRO_FOREACH(INSERT_POINT, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9)
  QOOL_MACRO_FOREACH(
    INSERT_POINT, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19)
  QOOL_MACRO_FOREACH(INSERT_POINT, 20, 21, 22, 23, 24)
  QOOL_MACRO_FOREACH(INSERT_POINT, A, B, C, D, E, F, G, H, I, J, K, L,
    M, N, O, P, Q, R, S, T, U, V, W, X, Y, Z)
#undef INSERT_POINT

  QStringList results;
  for (auto iter = points.constBegin(); iter != points.constEnd();
    ++iter) {
    if (iter.value().x() == 0 || iter.value().y() == 0)
      continue;
    results << QString("%1(%2,%3)")
                 .arg(iter.key())
                 .arg(iter.value().x(), 3, 'g', -1, u' ')
                 .arg(iter.value().y(), 3, 'g', -1, u' ');
  }

  xDebugQ << results;
}

#define IMPL_POINT(_N_)                                                \
  qreal ShapeHelper::point##_N_##x() const {                           \
    return m_point##_N_##x.value();                                    \
  }                                                                    \
  void ShapeHelper::set_point##_N_##x(const qreal& v) {                \
    m_point##_N_##x = v;                                               \
  }                                                                    \
  qreal ShapeHelper::point##_N_##y() const {                           \
    return m_point##_N_##y.value();                                    \
  }                                                                    \
  void ShapeHelper::set_point##_N_##y(const qreal& v) {                \
    m_point##_N_##y = v;                                               \
  }                                                                    \
  QPointF ShapeHelper::point##_N_() const {                            \
    return QPointF { point##_N_##x(), point##_N_##y() };               \
  }                                                                    \
  void ShapeHelper::set_point##_N_(const QPointF& p) {                 \
    Qt::beginPropertyUpdateGroup();                                    \
    m_point##_N_##x = p.x();                                           \
    m_point##_N_##y = p.y();                                           \
    Qt::endPropertyUpdateGroup();                                      \
  }                                                                    \
  QBindable<qreal> ShapeHelper::bindable_point##_N_##x() {             \
    return &m_point##_N_##x;                                           \
  }                                                                    \
  QBindable<qreal> ShapeHelper::bindable_point##_N_##y() {             \
    return &m_point##_N_##y;                                           \
  }                                                                    \
  void ShapeHelper::__setup_point##_N_() {                             \
    connect(this, &ShapeHelper::point##_N_##xChanged, this,            \
      &ShapeHelper::point##_N_##Changed);                              \
    connect(this, &ShapeHelper::point##_N_##yChanged, this,            \
      &ShapeHelper::point##_N_##Changed);                              \
  }                                                                    \
  QBindable<QPointF> ShapeHelper::bindable_point##_N_() {              \
    return QBindable<QPointF>(this, "point" #_N_);                     \
  }

QOOL_MACRO_FOREACH(IMPL_POINT, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9)
QOOL_MACRO_FOREACH(IMPL_POINT, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19)
QOOL_MACRO_FOREACH(IMPL_POINT, 20, 21, 22, 23, 24)
QOOL_MACRO_FOREACH(IMPL_POINT, A, B, C, D, E, F, G, H, I, J, K, L, M, N,
  O, P, Q, R, S, T, U, V, W, X, Y, Z)

#undef IMPL_POINT

void ShapeHelper::__setup_all_points() {
#define SETUP_P(NAME) __setup_point##NAME();
  QOOL_MACRO_FOREACH(SETUP_P, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9);
  QOOL_MACRO_FOREACH(SETUP_P, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19);
  QOOL_MACRO_FOREACH(SETUP_P, 20, 21, 22, 23, 24);
  QOOL_MACRO_FOREACH(SETUP_P, A, B, C, D, E, F, G, H, I, J, K, L, M, N,
    O, P, Q, R, S, T, U, V, W, X, Y, Z);
#undef SETUP_P
} // __setup_all_points

QOOL_NS_END
