#ifndef QOOL_STYLEGROUPAGENT_H
#define QOOL_STYLEGROUPAGENT_H

#include "qool_theme.h"
#include "qoolcommon/bindable_property_macros_for_qobject.hpp"
#include "qoolcommon/macro_foreach.hpp"
#include "qoolcommon/property_macros_for_qobject.hpp"
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
  explicit StyleGroupAgent(Style* parent = nullptr);
  void setData(const QVariantMap& data);

  void setParentStyle(Style* s);
  Style* parentStyle() const;

  void inherit(StyleGroupAgent* other);

protected:
  QVariantMap m_data;
  Style* m_parentStyle;
  bool m_customed { false };

  /********** PROPERTIES ***********/

#define DECL(T, N)                                                     \
public:                                                                \
  T N() const;                                                         \
  void set_##N(const T& v);                                            \
  QBindable<T> bindable_##N();                                         \
  void reset_##N();                                                    \
  Q_SIGNAL void N##Changed();                                          \
                                                                       \
private:                                                               \
  bool m_##N##Customed { false };                                      \
  Q_OBJECT_BINDABLE_PROPERTY(                                          \
    StyleGroupAgent, T, m_##N, &StyleGroupAgent::N##Changed)           \
  Q_PROPERTY(T N READ N WRITE set_##N RESET reset_##N NOTIFY           \
      N##Changed BINDABLE bindable_##N)

#define __HANDLE__(N) DECL(QColor, N)
  QOOL_FOREACH_10(__HANDLE__, white, silver, grey, black, red, maroon,
    yellow, olive, lime, green)
  QOOL_FOREACH_10(__HANDLE__, aqua, cyan, teal, blue, navy, fuchsia,
    purple, orange, brown, pink)
  QOOL_FOREACH_3(__HANDLE__, positive, negative, warning)
  QOOL_FOREACH_3(
    __HANDLE__, controlBackgroundColor, controlBorderColor, infoColor)
  QOOL_FOREACH_10(__HANDLE__, accent, light, midlight, dark, mid,
    shadow, highlight, highlightedText, link, linkVisited)
  QOOL_FOREACH_10(__HANDLE__, text, base, alternateBase, window,
    windowText, button, buttonText, placeholderText, toolTipBase,
    toolTipText)
#undef __HANDLE__

#define __HANDLE__(N) DECL(int, N)
  QOOL_FOREACH_8(__HANDLE__, textSize, titleTextSize, toolTipTextSize,
    importantTextSize, decorativeTextSize, controlTitleTextSize,
    controlTextSize, windowTitleTextSize)
#undef __HANDLE__

#define __HANDLE__(N) DECL(qreal, N)
  QOOL_FOREACH_3(
    __HANDLE__, instantDuration, transitionDuration, movementDuration)
  QOOL_FOREACH_5(__HANDLE__, menuCutSize, buttonCutSize, controlCutSize,
    windowCutSize, dialogCutSize)
  QOOL_FOREACH_3(__HANDLE__, controlBorderWidth, windowBorderWidth,
    dialogBorderWidth)
  QOOL_FOREACH_2(__HANDLE__, windowElementSpacing, windowEdgeSpacing)
#undef __HANDLE__

  DECL(QStringList, papaWords)

#undef DECL
};

QOOL_NS_END

#endif // QOOL_STYLEGROUPAGENT_H
