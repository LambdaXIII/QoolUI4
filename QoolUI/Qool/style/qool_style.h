#ifndef QOOL_STYLE_H
#define QOOL_STYLE_H

#include "qool_itemtracker.h"
#include "qool_theme.h"
#include "qoolcommon/bindable_property_macros_for_qobject.hpp"
#include "qoolcommon/macro_foreach.hpp"
#include "qoolcommon/property_macros_for_qobject.hpp"
#include "qoolcommon/property_macros_for_qobject_declonly.hpp"
#include "qoolns.hpp"

#include <QBindable>
#include <QColor>
#include <QObject>
#include <QQmlEngine>
#include <QQuickAttachedPropertyPropagator>
#include <QQuickItem>

Q_MOC_INCLUDE("qool_stylegroupagent.h")

QOOL_NS_BEGIN
class StyleGroupAgent;
class Style: public QQuickAttachedPropertyPropagator {
  Q_OBJECT
  QML_ELEMENT
  QML_ATTACHED(QOOL_NS::Style)
  QML_UNCREATABLE(
    "It's an attached item. Creating directly is forbidden.")

public:
  explicit Style(QObject* parent = nullptr);
  virtual ~Style();
  // Q_INVOKABLE void dumpInfo() const;

  static Style* qmlAttachedProperties(QObject* object);

  QString theme() const;
  void setTheme(const QString& theme);
  void resetTheme();
  Q_SIGNAL void themeChanged();

  Q_INVOKABLE void dumpInfo() const;

protected:
  Q_PROPERTY(QString theme READ theme WRITE setTheme RESET resetTheme
      NOTIFY themeChanged)
  Theme m_currentTheme;
  // bool m_explicitCustomed { false };
  ItemTracker* m_itemTracker;
  void __setup_properties();
  void __spread_theme_values();
  QOOL_BINDABLE_MEMBER(Style, StyleGroupAgent*, currentAgent)

  void attachedParentChange(QQuickAttachedPropertyPropagator* newParent,
    QQuickAttachedPropertyPropagator* oldParent) override;
  void inherit(Style* other);
  void __propagate_theme();
  void __copy_values(Style* other);

  /********** PROPERTIES *********/

  QOOL_PROPERTY_CONSTANT_FOR_QOBJECT(StyleGroupAgent*, active, nullptr)
  QOOL_PROPERTY_CONSTANT_FOR_QOBJECT(
    StyleGroupAgent*, inactive, nullptr)
  QOOL_PROPERTY_CONSTANT_FOR_QOBJECT(
    StyleGroupAgent*, disabled, nullptr)

#define DECL(T, N)                                                     \
  QOOL_PROPERTY_WRITABLE_FOR_QOBJECT_BINDABLE(Style, T, N)

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

  QOOL_PROPERTY_WRITABLE_FOR_QOBJECT_DECL(bool, animationEnabled)
protected:
  bool m_animationEnabledCustomed { false };
  bool m_animationEnabled { true };
  void __inherit_animationEnabled(Style* other);
  void __propagate_animationEnabled();
};

QOOL_NS_END

#endif // QOOL_STYLE_H
