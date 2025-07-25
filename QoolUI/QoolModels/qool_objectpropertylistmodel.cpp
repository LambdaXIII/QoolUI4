#include "qool_objectpropertylistmodel.h"

#include "qoolcommon/math/utils.hpp"

#include <QMetaObject>
#include <QObject>
#include <qmetaobject.h>

QOOL_NS_BEGIN

ObjectPropertyListModel::ObjectPropertyListModel(QObject* parent)
  : QAbstractListModel(parent) {
}

QHash<int, QByteArray> ObjectPropertyListModel::roleNames() const {
  static QHash<int, QByteArray> names;
  if (names.isEmpty()) {
    names = QAbstractListModel::roleNames();
    names[KeyRole] = "key";
    names[ValueRole] = "value";
    names[IndexRole] = "index";
    names[ObjectRole] = "object";
  }
  return names;
}

int ObjectPropertyListModel::rowCount(const QModelIndex& parent) const {
  // For list models only the root node (an invalid parent) should
  // return the list's size. For all other (valid) parents, rowCount()
  // should return 0 so that it does not become a tree model.
  if (parent.isValid())
    return 0;
  return m_data.count();
}

QVariant ObjectPropertyListModel::data(
  const QModelIndex& index, int role) const {
  if (! index.isValid())
    return QVariant();

  if (role == ObjectRole)
    return m_object;

  const int row = index.row();
  if (role == IndexRole)
    return row;

  const QString& key = m_keys[row];
  if (role == KeyRole)
    return key;

  const QVariant& value = m_data[key];
  if (role == ValueRole)
    return value;

  if (value.typeId() == QMetaType::QVariantMap) {
    const auto role_names = roleNames();
    const QString sub_key = QString::fromUtf8(role_names.value(role));

    const QVariantMap data_map = value.value<QVariantMap>();
    if (data_map.contains(sub_key))
      return data_map.value(sub_key);
  }

  return QVariant();
}

QString ObjectPropertyListModel::key(int index) const {
  if (m_keys.isEmpty())
    return {};
  index = math::cycle_in_range<int>(0, index, m_keys.length() - 1);
  return m_keys.value(index);
}

QVariant ObjectPropertyListModel::value(const QString& key) const {
  return m_data.value(key);
}

QVariant ObjectPropertyListModel::value(int index) const {
  return m_data.value(key(index));
}

QVariant ObjectPropertyListModel::object() const {
  return m_object;
}

void ObjectPropertyListModel::set_object(const QVariant& obj) {
  if (m_object == obj)
    return;
  m_object = obj;
  beginResetModel();

  m_data.clear();
  m_keys.clear();

  if (obj.typeId() == QMetaType::QVariantMap) {
    m_data = obj.value<QVariantMap>();
    m_keys = m_data.keys();
  } else if (obj.typeId() == QMetaType::QVariantList) {
    const QVariantList x = obj.toList();
    for (int i = 0; i < x.length(); i++) {
      const auto key = QString::number(i);
      m_keys << key;
      m_data[key] = x[i];
    }
  } else if (obj.typeId() == QMetaType::QObjectStar) {
    QObject* x = obj.value<QObject*>();
    const QMetaObject* meta = x->metaObject();
    for (int i = meta->propertyOffset(); i < meta->propertyCount();
      i++) {
      const auto p = meta->property(i);
      const QString key(p.name());
      m_keys << key;
      m_data[key] = p.read(x);
    }
  } else {
    const QString key { "object" };
    m_keys << key;
    m_data[key] = obj;
  }

  endResetModel();
}

QOOL_NS_END
