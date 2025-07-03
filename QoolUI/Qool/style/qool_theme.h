#ifndef QOOL_THEME_H
#define QOOL_THEME_H

#include "qoolns.hpp"

#include <QObject>
#include <QPalette>
#include <QQmlEngine>
#include <QReadWriteLock>

QOOL_NS_BEGIN

class QoolTheme {
  Q_GADGET
  QML_VALUE_TYPE(qooltheme)
  QML_STRUCTURED_VALUE

public:
  enum ValueGroups {
    Active = QPalette::Active,
    Inactive = QPalette::Inactive,
    Disabled = QPalette::Disabled,
    CustomGroup = Qt::UserRole + 1
  };
  Q_ENUM(ValueGroups)

  QoolTheme();
  QoolTheme(const QString& name, const QVariantMap& active,
    const QVariantMap& inactive, const QVariantMap& disabled);
  QoolTheme(const QVariantMap& metadatas, const QVariantMap& active,
    const QVariantMap& inactive, const QVariantMap& disabled);

  QoolTheme(const QoolTheme&);
  QoolTheme(QoolTheme&&);

  QoolTheme& operator=(const QoolTheme&);
  QoolTheme& operator=(QoolTheme&&);

  ~QoolTheme();

  QString name() const;
  bool setName(const QString& value);

  QStringList keys() const;

  Q_INVOKABLE QVariant value(ValueGroups group, QAnyStringView key,
    const QVariant& defvalue = {}) const;
  Q_INVOKABLE bool setVallue(
    ValueGroups group, QAnyStringView key, const QVariant& value);

  Q_INVOKABLE QVariant metadata(
    QAnyStringView key, const QVariant& defvalue = {}) const;
  Q_INVOKABLE bool set_metadata(
    QAnyStringView key, const QVariant& value);

  Q_INVOKABLE bool contains(
    ValueGroups group, QAnyStringView key) const;
  Q_INVOKABLE bool contains(QAnyStringView key) const;
  Q_INVOKABLE bool containsMetadata(QAnyStringView key) const;

  Q_INVOKABLE void insert(ValueGroups group, const QVariantMap& datas);
  Q_INVOKABLE void insert(const QoolTheme& other);
  Q_INVOKABLE void insertMetadatas(const QVariantMap& datas);

  Q_INVOKABLE QVariantMap collapse(
    ValueGroups group = ValueGroups::Active) const;

  Q_INVOKABLE bool isEmpty() const;

  bool operator==(const QoolTheme& other) const;
  bool operator!=(const QoolTheme& other) const;

private:
  QMap<int, QVariantMap> m_data;
  QVariantMap m_metadata;
  QReadWriteLock* m_lock;

  Q_PROPERTY(QString name READ name WRITE setName)
  Q_PROPERTY(QStringList keys READ keys CONSTANT)
};

QOOL_NS_END

#endif // QOOL_THEME_H
