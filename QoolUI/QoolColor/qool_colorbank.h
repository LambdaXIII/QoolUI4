#ifndef QOOL_COLORBANK_H
#define QOOL_COLORBANK_H

#include <QObject>

#include "qoolcommon/qobject_property_macros.hpp"
#include "qoolns.hpp"

#include <QColor>
#include <QQmlEngine>

QOOL_NS_BEGIN

class ColorBank : public QObject {
  Q_OBJECT
  QML_ELEMENT

public:
  explicit ColorBank(QObject* parent = nullptr);

  Q_SIGNAL void cellColorUpdated(int index);

  Q_INVOKABLE QColor cellColor(int i) const;
  Q_INVOKABLE void setCellColor(int i, const QColor& color);
  Q_INVOKABLE void eraseCellColor(int i);

  Q_INVOKABLE QList<QColor> cellColors() const;
  Q_INVOKABLE void setCellColors(const QList<QColor>& colors);
  Q_INVOKABLE void clear();

protected:
  int m_minimumCells{24};
  QColor m_defaultColor{Qt::transparent};
  QMap<int, QColor> m_colors;

  std::set<int> empty_cell_indexes() const;

  QOBJECT_WRITABLE_PROPERTY_DECLARE(QColor, defaultColor)

  QOBJECT_READONLY_PROPERTY_DECLARE(int, cells)
  QOBJECT_READONLY_PROPERTY_DECLARE(QList<int>, validCellIndexes)
};

QOOL_NS_END
#endif // QOOL_COLORBANK_H
