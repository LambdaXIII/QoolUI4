#ifndef QOOL_THEME_H
#define QOOL_THEME_H

#include "qoolns.hpp"

#include <QMutex>
#include <QObject>
#include <QPalette>
#include <QQmlEngine>

QOOL_NS_BEGIN

class Theme {
  Q_GADGET
  QML_VALUE_TYPE(qooltheme)
  QML_STRUCTURED_VALUE

public:
  enum Groups {
    Constants = QPalette::Active - 1,
    Active = QPalette::Active,
    Inactive = QPalette::Inactive,
    Disabled = QPalette::Disabled,
    Custom = QPalette::Disabled + 1
  };
  Q_ENUM(Groups)
  static const std::array<Groups, 5> GROUPS;

  Theme();
  Theme(const QString& name, const QVariantMap& constants,
    const QVariantMap& active, const QVariantMap& inactive,
    const QVariantMap& disabled, const QVariantMap& custom = {});
  Theme(const QVariantMap& metadatas, const QVariantMap& constants,
    const QVariantMap& active, const QVariantMap& inactive,
    const QVariantMap& disabled, const QVariantMap& custom = {});

  Theme(const Theme&);
  Theme(Theme&&);

  Theme& operator=(const Theme&);
  Theme& operator=(Theme&&);

  ~Theme();

  QString name() const;
  bool setName(const QString& value);

  QStringList keys() const;

  Q_INVOKABLE QVariant value(Groups group, const QString& key,
    const QVariant& defvalue = {}) const;
  Q_INVOKABLE QVariant value(
    const QString& key, const QVariant& defvalue = {}) const;
  Q_INVOKABLE bool setValue(
    Groups group, const QString& key, const QVariant& value);
  Q_INVOKABLE bool setCustomValue(
    const QString& key, const QVariant& value);

  Q_INVOKABLE QVariant metadata(
    const QString& key, const QVariant& defvalue = {}) const;
  Q_INVOKABLE bool set_metadata(
    const QString& key, const QVariant& value);

  Q_INVOKABLE bool contains(Groups group, const QString& key) const;
  Q_INVOKABLE bool contains(const QString& key) const;
  Q_INVOKABLE bool containsMetadata(const QString& key) const;

  Q_INVOKABLE void insert(Groups group, const QVariantMap& datas);
  Q_INVOKABLE void insert(const Theme& other);
  Q_INVOKABLE void insertMetadatas(const QVariantMap& datas);

  Q_INVOKABLE bool isEmpty() const;

  bool operator==(const Theme& other) const;
  bool operator!=(const Theme& other) const;

  Q_INVOKABLE QVariantMap flatMap(Groups group) const;

protected:
  QHash<int, QVariantMap> m_data;
  QVariantMap m_metadata;
  QMutex* m_mutex;

  Q_PROPERTY(QString name READ name WRITE setName)
  Q_PROPERTY(QStringList keys READ keys CONSTANT)
};

QOOL_NS_END

#endif // QOOL_THEME_H
