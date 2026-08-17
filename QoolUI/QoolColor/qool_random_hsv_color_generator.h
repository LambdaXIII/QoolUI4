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
  // 专项注释（缺陷修复）：迁移静默丢失了 v3 的 QML 只读属性 previous（默认
  // Qt::white、带 previousChanged 信号），只剩私有成员且初值为无效色；v4 文档
  // 仍写明"previous 为默认白色"，与代码矛盾。用宏恢复（宏展开成员非 mutable，
  // 故 generate()/check_previous() 同步恢复非 const——与 v3 签名一致）。
  QOBJECT_READONLY_PROPERTY(QColor, previous, Qt::white)
  QRecursiveMutex* m_mutex;
  bool check_previous(const QColor& color);
  int randomHue() const;
  int randomSat() const;
  int randomVal() const;
  int randomAlf() const;

// 专项注释（缺陷修复）：属性名必须与 v3 的 minimumX/maximumX 一致——迁移
// 静默改名为 minX/maxX（QML 对未知属性赋值静默忽略，v3 风格消费方写入全部
// 落空、退回默认区间，生成颜色范围改变；v4 文档属性块仍用 v3 旧名，证明
// 改名并非有意决策）。恢复 v3 名。
#define DECL(N, MIN, MAX, PREF)                                          \
  QOBJECT_WRITABLE_PROPERTY(qreal, minimum##N, MIN)                      \
  QOBJECT_WRITABLE_PROPERTY(qreal, maximum##N, MAX)                      \
  QOBJECT_WRITABLE_PROPERTY(qreal, preferred##N, PREF)                   \
protected:                                                               \
  /* 专项注释（缺陷修复）：迁移丢失了 v3 的越界钳制（循环域 -1 缺陷），  \
     现用 math::auto_bound 合理钳制到 [0,1]（保持 qRound 量化）。*/      \
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
