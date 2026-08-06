#ifndef QOOL_COLORHUECYCLEMODEL_H
#define QOOL_COLORHUECYCLEMODEL_H

#include "qoolcommon/qobject_property_macros.hpp"
#include "qoolns.hpp"

#include <QAbstractListModel>
#include <QColor>
#include <QQmlEngine>
#include <utility>

QOOL_NS_BEGIN

class ColorHueCycleModel : public QAbstractListModel {
  Q_OBJECT
  QML_ELEMENT

public:
  enum Role {
    ColorRole,
    HueRole,
    SaturationRole,
    ValueRole,
    PositionRole
  };

  explicit ColorHueCycleModel(QObject* parent = nullptr);

  int rowCount(const QModelIndex& parent = QModelIndex()) const override;
  QVariant data(
    const QModelIndex& index, int role = Qt::DisplayRole) const override;
  QHash<int, QByteArray> roleNames() const override;

protected:
  std::pair<qreal, qreal> hue_and_position(int index) const;

  QOBJECT_WRITABLE_PROPERTY_DECLARE(int, number)
  QOBJECT_WRITABLE_PROPERTY_DECLARE(qreal, hueOffset)
  QOBJECT_WRITABLE_PROPERTY_DECLARE(qreal, saturation)
  QOBJECT_WRITABLE_PROPERTY_DECLARE(qreal, value)

  int m_number { 16 };
  qreal m_hueOffset { 0 };
  qreal m_saturation { 1 };
  qreal m_value { 1 };
};

QOOL_NS_END

#endif // QOOL_COLORHUECYCLEMODEL_H
