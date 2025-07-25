#ifndef QOOL_OBJECTPROPERTYLISTMODEL_H
#define QOOL_OBJECTPROPERTYLISTMODEL_H

#include "qoolcommon/property_macros_for_qobject_declonly.hpp"
#include "qoolns.hpp"

#include <QAbstractListModel>
#include <QQmlEngine>
#include <QVariantMap>

QOOL_NS_BEGIN

class ObjectPropertyListModel: public QAbstractListModel {
  Q_OBJECT
  QML_ELEMENT

public:
  explicit ObjectPropertyListModel(QObject* parent = nullptr);

  enum Role {
    KeyRole = Qt::UserRole + 1,
    ValueRole,
    IndexRole,
    ObjectRole
  };
  QHash<int, QByteArray> roleNames() const override;

  int rowCount(
    const QModelIndex& parent = QModelIndex()) const override;

  QVariant data(const QModelIndex& index,
    int role = Qt::DisplayRole) const override;

  Q_INVOKABLE QString key(int index) const;
  Q_INVOKABLE QVariant value(const QString& key) const;
  Q_INVOKABLE QVariant value(int index) const;

private:
  QVariantMap m_data;
  QStringList m_keys;
  QVariant m_object;

  QOOL_PROPERTY_WRITABLE_FOR_QOBJECT_DECL(QVariant, object)
};

QOOL_NS_END

#endif // QOOL_OBJECTPROPERTYLISTMODEL_H
