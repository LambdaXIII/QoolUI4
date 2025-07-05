#ifndef QOOL_SYSTEM_THEME_H
#define QOOL_SYSTEM_THEME_H

#include "qool_theme.h"
#include "qoolcommon/singleton.hpp"
#include "qoolns.hpp"

QOOL_NS_BEGIN

class SystemTheme: public Theme {
  QOOL_SIMPLE_SINGLETON_DECL(SystemTheme)

public:
};

QOOL_NS_END

#endif // QOOL_SYSTEM_THEME_H
