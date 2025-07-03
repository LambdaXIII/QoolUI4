#ifndef QOOL_THEME_PACKAGE_H
#define QOOL_THEME_PACKAGE_H

#include "qoolns.hpp"

#include <QQmlEngine>
#include <QSharedDataPointer>
#include <QUuid>
#include <QVariantMap>

QOOL_NS_BEGIN

class ThemePackage {
  Q_GADGET
  QML_VALUE_TYPE(themepackage)
  QML_STRUCTURED_VALUE
  // QML_ANONYMOUS
  Q_PROPERTY(QVariantMap active READ active CONSTANT)
  Q_PROPERTY(QVariantMap inactive READ inactive CONSTANT)
  Q_PROPERTY(QVariantMap disabled READ disabled CONSTANT)
  Q_PROPERTY(QVariantMap metadata READ metadata CONSTANT)
  Q_PROPERTY(QString name READ name CONSTANT)

public:
  ThemePackage();
  ThemePackage(const QString& name, const QVariantMap& active);
  ThemePackage(const QString& name, const QVariantMap& active,
    const QVariantMap& inactive, const QVariantMap& disabled,
    const QVariantMap& metadata);
  ThemePackage(const ThemePackage& other);

  QVariant activeValue(
    const QString& key, const QVariant& defaultValue = {}) const;
  QVariant inactiveValue(
    const QString& key, const QVariant& defaultValue = {}) const;
  QVariant disabledValue(
    const QString& key, const QVariant& defaultValue = {}) const;
  Q_INVOKABLE bool contains(const QString& key) const;
  Q_INVOKABLE QVariant value(
    const QString& key, const QVariant& defaultValue = {}) const;
  QVariant data(
    const QString& key, const QVariant& odefaultValue = {}) const;

  QVariantMap active() const;
  QVariantMap inactive() const;
  QVariantMap disabled() const;
  QVariantMap metadata() const;

  QString name() const;

protected:
  struct Data: public QSharedData {
    QString name;
    QVariantMap active, inactive, disabled, metadata;
    Data()
      : QSharedData() {
      name = QUuid::createUuid().toString(QUuid::WithoutBraces);
    }
    Data(const Data& other)
      : QSharedData(other)
      , name(other.name)
      , active(other.active)
      , inactive(other.inactive)
      , disabled(other.disabled)
      , metadata(other.metadata) {}
  };
  QSharedDataPointer<Data> m_pData;
};

QOOL_NS_END

Q_DECLARE_METATYPE(QOOL_NS::ThemePackage)

#endif // QOOL_THEME_H