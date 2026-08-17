#ifndef QOOL_RANDOM_HSV_COLOR_GENERATOR_H
#define QOOL_RANDOM_HSV_COLOR_GENERATOR_H

#include "qoolcommon/qobject_property_macros.hpp"
#include "qoolcommon/math/utils.hpp"
#include "qoolns.hpp"

#include <QColor>
#include <QObject>
#include <QQmlEngine>
#include <QRecursiveMutex>

QOOL_NS_BEGIN

class RandomHSVColorGenerator : public QObject {
  Q_OBJECT
  QML_ELEMENT

public:
  explicit RandomHSVColorGenerator(QObject* parent = nullptr);
  ~RandomHSVColorGenerator();

  Q_INVOKABLE QColor generate();
  Q_INVOKABLE int count() const;

protected:
  // previous 为公开只读属性（默认 Qt::white、带 previousChanged 信号）。
  // 宏展开成员非 mutable，故 generate()/check_previous() 为非 const。
  QOBJECT_READONLY_PROPERTY(QColor, previous, Qt::white)
  QRecursiveMutex* m_mutex;
  bool check_previous(const QColor& color);
  int randomHue() const;
  int randomSat() const;
  int randomVal() const;
  int randomAlf() const;

// 属性名固定为 minimumX/maximumX（公开 QML API）：QML 对未知属性赋值
// 静默忽略，改名会使消费方写入落空、退回默认区间。
#define DECL(N, MIN, MAX, PREF)                                          \
  QOBJECT_WRITABLE_PROPERTY(qreal, minimum##N, MIN)                      \
  QOBJECT_WRITABLE_PROPERTY(qreal, maximum##N, MAX)                      \
  QOBJECT_WRITABLE_PROPERTY(qreal, preferred##N, PREF)                   \
protected:                                                               \
  /* 越界钳制：math::auto_bound 钳制到 [0,1]（保持 qRound 量化）。*/     \
  int _min##N() const { return qRound(math::auto_bound(0.0, m_minimum##N, 1.0) * 255); } \
  int _max##N() const { return qRound(math::auto_bound(0.0, m_maximum##N, 1.0) * 255); } \
  int _preferred##N() const { return qRound(math::auto_bound(0.0, m_preferred##N, 1.0) * 255); }

  DECL(Hue, 0, 1, -1)
  DECL(Saturation, 0.25, 1, -1)
  DECL(Value, 0.25, 1, -1)
  DECL(Alpha, 0, 1, 1)

#undef DECL

  QOBJECT_WRITABLE_PROPERTY(QList<QColor>, blackList, )
  QOBJECT_WRITABLE_PROPERTY(QList<QColor>, whiteList, )
};

QOOL_NS_END

#endif // QOOL_RANDOM_HSV_COLOR_GENERATOR_H
