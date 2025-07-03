#ifndef QOOL_THEME_VALUES_SUPPORT_H
#define QOOL_THEME_VALUES_SUPPORT_H

#include "qoolcommon/macro_foreach.hpp"
#include "qoolns.hpp"

#include <QString>
#include <QVariant>

QOOL_NS_BEGIN

struct ThemeValueGroupInterface {
  virtual ~ThemeValueGroupInterface() = default;

  virtual bool contains(const QString&) const = 0;
  virtual QVariant value(const QString&, const QVariant&) const = 0;
  virtual void setValue(const QString&, const QVariant&) = 0;
  virtual void reset(const QString&) = 0;
  virtual void reset() = 0;
  virtual void setDefaults(const QVariantMap&) = 0;

  // value decls

#define DECL(T, N)                                                     \
  virtual T N() const = 0;                                             \
  virtual void set_##N(const T&) = 0;

#define DECL_COLOR(N) DECL(QColor, N)
  QOOL_FOREACH_10(DECL_COLOR, window, windowText, base, alternateBase,
    toolTipBase, toolTipText, placeholderText, text, button, buttonText)
  QOOL_FOREACH_5(DECL_COLOR, light, midlight, dark, mid, shadow)
  QOOL_FOREACH_3(DECL_COLOR, highlight, accent, highlightedText)
  QOOL_FOREACH_2(DECL_COLOR, link, linkVisited)
  QOOL_FOREACH_3(DECL_COLOR, positive, negative, warning)
#undef DECL_COLOR

#define DECL_REAL(N) DECL(qreal, N)
  QOOL_FOREACH_5(DECL_REAL, windowCutSize, controlCutSize, menuCutSize,
    dialogCutSize, buttonCutSize)
  QOOL_FOREACH_2(DECL_REAL, transitionDuration, movementDuration)
#undef DECL_REAL

#define DECL_INT(N) DECL(int, N)
  QOOL_FOREACH_6(DECL_INT, titleTextSize, toolTipTextSize,
    controlTextSize, importantTextSize, decorativeTextSize,
    controlTitleTextSize)
#undef DECL_INT

  DECL(bool, animationEnabled)
  DECL(QStringList, papaWords)
#undef DECL

}; // ThemeValueGroupInterface

QOOL_NS_END

#endif // QOOL_THEME_VALUES_SUPPORT_H
