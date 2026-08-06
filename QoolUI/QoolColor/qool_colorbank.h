#ifndef QOOL_COLORBANK_H
#define QOOL_COLORBANK_H

#include "qoolns.hpp"

#include <QColor>
#include <QHash>
#include <QList>
#include <QObject>
#include <QQmlEngine>

QOOL_NS_BEGIN

class ColorBank : public QObject {
  Q_OBJECT
  QML_ELEMENT

public:
  explicit ColorBank(QObject* parent = nullptr);

  Q_INVOKABLE QColor color(int n) const;
  Q_INVOKABLE void setColor(int n, const QColor& color);
  Q_INVOKABLE QList<int> filledIndexes() const;

  Q_SIGNAL void colorChanged(int);

protected:
  // 稀疏存储：只保留被 setColor 显式写过的索引（存 5 不创建 1..4）。
  // 无界——索引不设上限，也不随"显示范围"收缩。
  QHash<int, QColor> m_colors;
};

QOOL_NS_END

#endif // QOOL_COLORBANK_H
