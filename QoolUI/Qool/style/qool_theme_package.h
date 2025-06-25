#ifndef QOOL_THEME_PACKAGE_H
#define QOOL_THEME_PACKAGE_H

#include "qoolns.hpp"

#include <QQmlEngine>
#include <QSharedDataPointer>
#include <QVariantMap>

QOOL_NS_BEGIN

class ThemePackage {
  Q_GADGET
  QML_VALUE_TYPE(themepackage)
  QML_ANONYMOUS
  Q_PROPERTY(QVariantMap active READ active CONSTANT)
  Q_PROPERTY(QVariantMap inactive READ inactive CONSTANT)
  Q_PROPERTY(QVariantMap disabled READ disabled CONSTANT)

public:
  ThemePackage();
  explicit ThemePackage(const QVariantMap& active);
  ThemePackage(const QVariantMap& active, const QVariantMap& inactive,
    const QVariantMap& disabled);
  ThemePackage(const ThemePackage& other);

  QVariant activeValue(
    const QString& key, const QVariant& defaultValue = {}) const;
  QVariant inactiveValue(
    const QString& key, const QVariant& defaultValue = {}) const;
  QVariant disabledValue(
    const QString& key, const QVariant& defaultValue = {}) const;
  QVariant value(const QString& key, const QVariant& other = {}) const;

  const QVariantMap& active() const;
  const QVariantMap& inactive() const;
  const QVariantMap& disabled() const;

protected:
  struct Data: public QSharedData {
    QVariantMap active, inactive, disabled;
    Data()
      : QSharedData() {}
    Data(const Data& other)
      : QSharedData(other)
      , active(other.active)
      , inactive(other.inactive)
      , disabled(other.disabled) {}
  };
  QSharedDataPointer<Data> m_pData;
};

QOOL_NS_END

#endif // QOOL_THEME_H