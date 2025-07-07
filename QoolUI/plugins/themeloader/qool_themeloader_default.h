#ifndef QOOLPLUGIN_DEFAULT_THEMELOADER_H
#define QOOLPLUGIN_DEFAULT_THEMELOADER_H

#include "qool_interface_themeloader.h"
#include "qoolns.hpp"

QOOL_NS_BEGIN

class DefaultThemeLoader
  : public QObject
  , public ThemeLoader {
  Q_OBJECT
  // Q_PLUGIN_METADATA(IID "org.qoolui.themeloader.default" FILE
  //                       "qool_themeloader_default.json")
  Q_PLUGIN_METADATA(
    IID QOOL_THEMELOADER_IID FILE "qool_themeloader_default.json")
  Q_INTERFACES(QOOL_NS::ThemeLoader)
public:
  DefaultThemeLoader();
  ~DefaultThemeLoader() = default;
  QList<Package> themes() const override;
};

QOOL_NS_END

#endif // QOOLPLUGIN_DEFAULT_THEMELOADER_H
