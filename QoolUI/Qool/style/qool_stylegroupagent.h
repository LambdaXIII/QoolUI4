#ifndef QOOL_STYLEGROUPAGENT_H
#define QOOL_STYLEGROUPAGENT_H

#include "qool_theme.h"
#include "qoolcommon/macro_foreach.hpp"
#include "qoolcommon/property_macros_for_qobject.hpp"
#include "qoolcommon/property_macros_for_qobject_declonly.hpp"
#include "qoolns.hpp"

#include <QColor>
#include <QObject>
#include <QQmlEngine>

Q_MOC_INCLUDE("qool_style.h")

QOOL_NS_BEGIN

class Style;
class StyleGroupAgent: public QObject {
  Q_OBJECT
  // QML_ELEMENT
  QML_ANONYMOUS
public:
  explicit StyleGroupAgent(
    Theme::Groups group, Style* parent = nullptr);

protected:
  friend class Style;
  Style* m_parentStyle;
  void update_values(QStringList keys);

  /********** PROPERTIES ***********/

  QOOL_PROPERTY_CONSTANT_FOR_QOBJECT(
    Theme::Groups, group, Theme::Active)

#define DECL(T, N) QOOL_PROPERTY_WRITABLE_FOR_QOBJECT_DECL(T, N)

#define __COLOR(N) DECL(QColor, N)
  QOOL_FOREACH_10(__COLOR, white, silver, grey, black, red, maroon,
    yellow, olive, lime, green)
  QOOL_FOREACH_10(__COLOR, aqua, cyan, teal, blue, navy, fuchsia,
    purple, orange, brown, pink)
  QOOL_FOREACH_3(__COLOR, positive, negative, warning)
  QOOL_FOREACH_3(
    __COLOR, controlBackgroundColor, controlBorderColor, infoColor)
  QOOL_FOREACH_10(__COLOR, accent, light, midlight, dark, mid, shadow,
    highlight, highlightedText, link, linkVisited)
  QOOL_FOREACH_10(__COLOR, text, base, alternateBase, window,
    windowText, button, buttonText, placeholderText, toolTipBase,
    toolTipText)
#undef __COLOR

#define __INT(N) DECL(int, N)
  QOOL_FOREACH_8(__INT, textSize, titleTextSize, toolTipTextSize,
    importantTextSize, decorativeTextSize, controlTitleTextSize,
    controlTextSize, windowTitleTextSize)
#undef __INT

#define __REAL(N) DECL(qreal, N)
  QOOL_FOREACH_3(
    __REAL, instantDuration, transitionDuration, movementDuration)
  QOOL_FOREACH_5(__REAL, menuCutSize, buttonCutSize, controlCutSize,
    windowCutSize, dialogCutSize)
  QOOL_FOREACH_3(
    __REAL, controlBorderWidth, windowBorderWidth, dialogBorderWidth)
  QOOL_FOREACH_2(__REAL, windowElementSpacing, windowEdgeSpacing)
#undef __REAL

  DECL(bool, animationEnabled)
  DECL(QStringList, papaWords)

#undef DECL
};

QOOL_NS_END

#endif // QOOL_STYLEGROUPAGENT_H
