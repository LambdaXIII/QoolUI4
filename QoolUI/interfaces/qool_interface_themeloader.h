#ifndef QOOL_INTERFACE_THEMELOADER_H
#define QOOL_INTERFACE_THEMELOADER_H

#include "qoolns.hpp"

#include <QMap>
#include <QString>
#include <QVariant>
#include <QVariantMap>
#include <QtPlugin>

QOOL_NS_BEGIN
struct ThemeLoader {
  struct Package {
    QString name;
    QVariantMap metadata;
    QVariantMap constants, active, inactive, disabled, custom;
  };
  virtual ~ThemeLoader() = default;
  virtual QList<Package> themes() const = 0;
};
QOOL_NS_END

#define QOOL_THEMELOADER_IID "com.qoolui.themeloader.interface"
Q_DECLARE_INTERFACE(QOOL_NS::ThemeLoader, QOOL_THEMELOADER_IID)

#endif // QOOL_INTERFACE_THEMELOADER_H