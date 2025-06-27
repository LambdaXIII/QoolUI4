#ifndef QOOL_STYLE_AGENT_GROUP_H
#define QOOL_STYLE_AGENT_GROUP_H

#include "qoolcommon/bindable_property_macros_for_qobject.hpp"
#include "qoolcommon/default_variant_map.hpp"
#include "qoolcommon/macro_foreach.hpp"
#include "qoolcommon/property_macros_for_qobject_declonly.hpp"
#include "qoolns.hpp"

#include <QObject>
#include <QQmlEngine>
#include <QVariantMap>

QOOL_NS_BEGIN

class StyleAgentGroup: public QObject {
  Q_OBJECT
  // QML_ELEMENT
  QML_ANONYMOUS

public:
  StyleAgentGroup(QObject* parent = nullptr);

  Q_INVOKABLE bool contains(const QString& name) const;
  Q_INVOKABLE QVariant value(const QString& name,
    const QVariant& defaultValue = QVariant()) const;
  Q_INVOKABLE void setValue(const QString& name, const QVariant& value);
  Q_INVOKABLE void reset(const QString& key = QString());
  Q_INVOKABLE QVariantMap values() const;

  void setDefaults(const QVariantMap& values);

  Q_SIGNAL void valueChanged(QString key);

  QBindable<QStringList> bindable_papaWords();

private:
  DefaultVariantMap m_values;
  Q_SIGNAL void valuesChangedInternally(QStringList keys);
  Q_SLOT void whenValuesChangedInternally(const QStringList& keys);

  QOOL_PROPERTY_WRITABLE_FOR_QOBJECT_BINDABLE(
    StyleAgentGroup, bool, animationEnabled)

  QOOL_PROPERTY_WRITABLE_FOR_QOBJECT_DECL(QStringList, papaWords)

#define DECL_COLOR(NAME)                                               \
  QOOL_PROPERTY_WRITABLE_FOR_QOBJECT_DECL(QColor, NAME)                \
public:                                                                \
  QBindable<QColor> bindable_##NAME();

  QOOL_FOREACH_10(DECL_COLOR, window, windowText, base, alternateBase,
    toolTipBase, toolTipText, placeholderText, text, button, buttonText)
  QOOL_FOREACH_5(DECL_COLOR, light, midlight, dark, mid, shadow)
  QOOL_FOREACH_3(DECL_COLOR, highlight, accent, highlightedText)
  QOOL_FOREACH_2(DECL_COLOR, link, linkVisited)
  QOOL_FOREACH_3(DECL_COLOR, positive, negative, warning)
#undef DECL_COLOR

#define DECL_REAL(NAME)                                                \
  QOOL_PROPERTY_WRITABLE_FOR_QOBJECT_DECL(qreal, NAME)                 \
public:                                                                \
  QBindable<qreal> bindable_##NAME();

  QOOL_FOREACH_5(DECL_REAL, windowCutSize, controlCutSize, menuCutSize,
    dialogCutSize, buttonCutSize)
  QOOL_FOREACH_2(DECL_REAL, transitionDuration, movementDuration)
#undef DECL_REAL

#define DECL_INT(NAME)                                                 \
  QOOL_PROPERTY_WRITABLE_FOR_QOBJECT_DECL(int, NAME)                   \
public:                                                                \
  QBindable<int> bindable_##NAME();

  QOOL_FOREACH_5(DECL_INT, titleTextSize, toolTipTextSize,
    controlTextSize, importantTextSize, decorativeTextSize)
#undef DECL_INT
};

QOOL_NS_END

#endif // QOOL_STYLE_AGENT_GROUP_H