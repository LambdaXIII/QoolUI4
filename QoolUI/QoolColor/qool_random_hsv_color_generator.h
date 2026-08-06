#ifndef QOOL_RANDOM_HSV_COLOR_GENERATOR_H
#define QOOL_RANDOM_HSV_COLOR_GENERATOR_H

#include "qoolcommon/qobject_property_macros.hpp"
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

  Q_INVOKABLE QColor generate() const;
  Q_INVOKABLE int combinationsCount() const;

protected:
  mutable QColor m_previous;
  QRecursiveMutex* m_mutex;
  bool check_previous(const QColor& color) const;
  int randomHue() const;
  int randomSat() const;
  int randomVal() const;
  int randomAlf() const;

#define DECL(N, MIN, MAX, PREF)                                      \
  QOBJECT_WRITABLE_PROPERTY(qreal, min##N, MIN)                      \
  QOBJECT_WRITABLE_PROPERTY(qreal, max##N, MAX)                      \
  QOBJECT_WRITABLE_PROPERTY(qreal, preferred##N, PREF)               \
protected:                                                           \
  int _min##N() const { return qRound(m_min##N * 255); }             \
  int _max##N() const { return qRound(m_max##N * 255); }             \
  int _preferred##N() const { return qRound(m_preferred##N * 255); }

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
