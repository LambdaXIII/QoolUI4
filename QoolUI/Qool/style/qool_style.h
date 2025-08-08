#ifndef QOOL_STYLE_H
#define QOOL_STYLE_H

#include "qool_itemtracker.h"
#include "qool_theme.h"
#include "qoolcommon/macro_foreach.hpp"
#include "qoolcommon/qbindable_property_macros.hpp"
#include "qoolcommon/qobject_property_macros.hpp"

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
class Style : public QQuickAttachedPropertyPropagator {
  Q_OBJECT
  QML_ELEMENT
  QML_ATTACHED(QOOL_NS::Style)
  QML_UNCREATABLE("")

public:
  explicit Style(QObject* parent = nullptr);

  static Style* qmlAttachedProperties(QObject* object);
  Q_INVOKABLE void dumpInfo() const;
  Q_INVOKABLE void dumpAllChildren() const;

  enum Groups {
    Active = Theme::Active,
    Inactive = Theme::Inactive,
    Disabled = Theme::Disabled
  };

  QVariant get_value(
      int group, const QString& key, const QVariant& defValue = {}) const;
  bool set_value(int group, const QString& key, const QVariant& value);

  Q_SIGNAL void valueChanged(int group, QString key);

  void mark_modified(int group, const QString& key);
  bool is_modified(int group, const QString& key) const;

protected:
  ItemTracker* m_itemTracker;
  QVariantMap m_activeData, m_inactiveData, m_disabledData;
  QMap<QString, bool> m_activeModified, m_inactiveModified, m_disabledModified;
  bool m_animationEnabled;

  QOOL_BINDABLE_MEMBER(Style, Groups, currentGroup);
  void initialize_data();
  void propagate_theme();
  void inherit(Style* other);
  Q_SLOT void when_themeChanged();
  Q_SLOT void check_changes(int group, QString key);
  Q_SLOT void when_curentGroupChanged();

  QList<QQuickAttachedPropertyPropagator*> find_children() const;

  void attachedParentChange(QQuickAttachedPropertyPropagator* newParent,
      QQuickAttachedPropertyPropagator* oldParent) override;

  bool eventFilter(QObject* object, QEvent* event) override;

  Style* m_follow{nullptr};
  Q_SLOT void follow_value(int group, QString key);

  /****** PROPERTIES ******/
  QOBJECT_WRITABLE_PROPERTY(QString, theme, )
  QOBJECT_WRITABLE_PROPERTY_DECLARE(bool, animationEnabled)
  QOBJECT_CONSTANT_PROPERTY(StyleGroupAgent*, active, )
  QOBJECT_CONSTANT_PROPERTY(StyleGroupAgent*, inactive, )
  QOBJECT_CONSTANT_PROPERTY(StyleGroupAgent*, disabled, )
  QOBJECT_WRITABLE_PROPERTY_DECLARE(Style*, follow)

#define DECL(T, N) QOBJECT_WRITABLE_PROPERTY_DECLARE(T, N)

#define __HANDLE__(N) DECL(QColor, N)
  QOOL_FOREACH_10(__HANDLE__, white, silver, grey, black, red, maroon, yellow,
      olive, lime, green)
  QOOL_FOREACH_10(__HANDLE__, aqua, cyan, teal, blue, navy, fuchsia, purple,
      orange, brown, pink)
  QOOL_FOREACH_3(__HANDLE__, positive, negative, warning)
  QOOL_FOREACH_3(
      __HANDLE__, controlBackgroundColor, controlBorderColor, infoColor)
  QOOL_FOREACH_10(__HANDLE__, accent, light, midlight, dark, mid, shadow,
      highlight, highlightedText, link, linkVisited)
  QOOL_FOREACH_10(__HANDLE__, text, base, alternateBase, window, windowText,
      button, buttonText, placeholderText, toolTipBase, toolTipText)
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
  QOOL_FOREACH_3(
      __HANDLE__, controlBorderWidth, windowBorderWidth, dialogBorderWidth)
  QOOL_FOREACH_2(__HANDLE__, windowElementSpacing, windowEdgeSpacing)
#undef __HANDLE__

  DECL(QStringList, papaWords)

#undef DECL
};

QOOL_NS_END

#endif // QOOL_STYLE_H
