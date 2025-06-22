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
  virtual ~ThemeLoader() = default;
  virtual QMap<QString, QVariantMap> themes() = 0;
};
QOOL_NS_END

#define QOOL_THEMELOADER_IID "com.qoolui.themeloader.interface"
Q_DECLARE_INTERFACE(QOOL_NS::ThemeLoader, QOOL_THEMELOADER_IID)

#endif // QOOL_INTERFACE_THEMELOADER_H