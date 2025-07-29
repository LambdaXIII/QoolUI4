#ifndef QOOL_STYLEGROUPAGENT_H
#define QOOL_STYLEGROUPAGENT_H

#include "qoolcommon/bindable_property_macros_for_qobject.hpp"
#include "qoolcommon/macro_foreach.hpp"
#include "qoolns.hpp"

#include <QColor>
#include <QObject>
#include <QQmlEngine>

Q_MOC_INCLUDE("qool_style.h")

QOOL_NS_BEGIN

class Style;
class StyleGroupAgent: public QObject {
  Q_OBJECT
  QML_ANONYMOUS
public:
  explicit StyleGroupAgent(Style* parent = nullptr);

  void setValues(const QVariantMap& values);
  QVariantMap flatMap() const;

  void attachTo(StyleGroupAgent* other);

protected:
  QVariantMap m_values, m_defaultValues;
  QMap<QString, bool> m_modified;
  StyleGroupAgent* m_parentAgent { nullptr };

  void connectTo(StyleGroupAgent* other);

  QOOL_PROPERTY_WRITABLE_FOR_QOBJECT_BINDABLE(
    StyleGroupAgent, Style*, parentStyle)

  /********** PROPERTIES ***********/

#define DECL(T, N)                                                     \
public:                                                                \
  T N() const;                                                         \
  void set_##N(const T& v);                                            \
  QBindable<T> bindable_##N();                                         \
  void reset_##N();                                                    \
  Q_SIGNAL void N##Changed(T);                                         \
                                                                       \
private:                                                               \
  Q_SLOT void update_##N##_from_parent(const T&);                      \
  Q_PROPERTY(T N READ N WRITE set_##N RESET reset_##N NOTIFY N##Changed)

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
