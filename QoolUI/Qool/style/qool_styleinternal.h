#ifndef QOOL_STYLEINTERNAL_H
#define QOOL_STYLEINTERNAL_H

#include "qoolcommon/bindable_property_macros_for_qobject.hpp"
#include "qoolcommon/macro_foreach.hpp"
#include "qoolns.hpp"

#include <QBindable>
#include <QColor>
#include <QObject>
#include <QQmlEngine>

QOOL_NS_BEGIN

class StyleInternal: public QObject {
  Q_OBJECT
  QML_ELEMENT
public:
  explicit StyleInternal(QObject* parent = nullptr);

#define DECL_ONE(T, N)                                                 \
public:                                                                \
  T N() const;                                                         \
  void set_##N(const T&);                                              \
  QBindable<T> bindable_##N();                                         \
  Q_SIGNAL void N##Changed();                                          \
                                                                       \
private:                                                               \
  T m_##N;                                                             \
  bool m_##N##_customed { false };                                     \
  Q_PROPERTY(                                                          \
    T N READ N WRITE set_##N NOTIFY N##Changed BINDABLE bindable_##N)

#define DECL(T, N)                                                     \
  DECL_ONE(T, active_##N)                                              \
  DECL_ONE(T, inactive_##N)                                            \
  DECL_ONE(T, disabled_##N)

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
#undef DECL_ONE
};

QOOL_NS_END

#endif // QOOL_STYLEINTERNAL_H
