#ifndef QOOL_STYLE_H
#define QOOL_STYLE_H

#include "qool_itemtracker.h"
#include "qool_theme.h"
#include "qoolcommon/bindable_property_macros_for_qobject.hpp"
#include "qoolcommon/default_variant_map.hpp"
#include "qoolcommon/macro_foreach.hpp"
#include "qoolcommon/property_macros.hpp"
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

public:
  enum Groups {
    Active = Theme::Active,
    Inactive = Theme::Inactive,
    Disabled = Theme::Disabled
  };
  Q_ENUM(Groups)

  explicit Style(QObject* parent = nullptr);
  virtual ~Style();

  static Style* qmlAttachedProperties(QObject* object);

  QVariant value(Theme::Groups group, QString key) const;
  void setValue(Theme::Groups group, QString key, QVariant value);

  Q_INVOKABLE void dumpInfo() const;

protected:
  Theme m_currentTheme;
  ItemTracker* m_itemTracker;
  QHash<Theme::Groups, QVariantMap*> m_data;
  QHash<Theme::Groups, StyleGroupAgent*> m_agents;
  void attachedParentChange(QQuickAttachedPropertyPropagator* newParent,
    QQuickAttachedPropertyPropagator* oldParent) override;

  void set_current_theme(const Theme& theme);
  void update_values(
    QList<Theme::Groups> groups = {}, QStringList keys = {});

  void inherit(Style* other);
  void propagate_theme();
  void propagate_value(
    Theme::Groups group, QString key, QVariant value);
  void update_customed_value(
    Theme::Groups group, QString key, QVariant value);

  /********** PROPERTIES *********/

  QOOL_PROPERTY_CONSTANT_FOR_QOBJECT_DECL(StyleGroupAgent*, active)
  QOOL_PROPERTY_CONSTANT_FOR_QOBJECT_DECL(StyleGroupAgent*, inactive)
  QOOL_PROPERTY_CONSTANT_FOR_QOBJECT_DECL(StyleGroupAgent*, disabled)

  QOOL_PROPERTY_WRITABLE_FOR_QOBJECT_DECL(QString, theme)
  QOOL_PROPERTY_READONLY_FOR_QOBJECT_BINDABLE(
    Style, Theme::Groups, currentGroup)

#define DECL(T, N)                                                     \
  QOOL_PROPERTY_WRITABLE_FOR_QOBJECT_BINDABLE_DECL(Style, T, N)

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

  DECL(QStringList, papaWords)
  DECL(bool, animationEnabled)

#undef DECL
};

QOOL_NS_END

#endif // QOOL_STYLE_H
