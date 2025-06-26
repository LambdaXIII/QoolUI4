#ifndef QOOL_DEFAULT_THEME_H
#define QOOL_DEFAULT_THEME_H

#include "qool_theme_package.h"
#include "qoolcommon/singleton.hpp"

QOOL_NS_BEGIN

class DefaultTheme: public ThemePackage {
  QOOL_SIMPLE_SINGLETON_DECL(DefaultTheme)

public:
  static ThemePackage copy();
};

QOOL_NS_END

#endif // QOOL_DEFAULT_THEME_H