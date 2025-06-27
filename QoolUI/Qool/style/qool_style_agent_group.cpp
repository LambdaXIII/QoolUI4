#include "qool_style_agent_group.h"

#include "qool_styledb.h"

#include <QColor>

QOOL_NS_BEGIN

StyleAgentGroup::StyleAgentGroup(QObject* parent) {
  connect(this, SIGNAL(valuesChangedInternally(QStringList)), this,
    SLOT(whenValuesChangedInternally(QStringList)));
}

bool StyleAgentGroup::contains(const QString& name) const {
  return m_values.contains(name);
}

QVariant StyleAgentGroup::value(
  const QString& name, const QVariant& defaultValue) const {
  if (m_values.contains(name))
    return m_values.value(name);
  return StyleDB::instance()->anyValue(name, defaultValue);
}

void StyleAgentGroup::setValue(
  const QString& name, const QVariant& value) {
  if (m_values.value(name) != value) {
    m_values.set_value(name, value);
    emit valuesChangedInternally({ name });
  }
}

void StyleAgentGroup::reset(const QString& name) {
  if (name.isEmpty()) {
    const QStringList keys = m_values.keys();
    m_values.reset();
    emit valuesChangedInternally(keys);
  }
  m_values.reset(name);
  emit valuesChangedInternally({ name });
}

QVariantMap StyleAgentGroup::values() const {
  return m_values.collapse();
}

void StyleAgentGroup::setDefaults(const QVariantMap& defaults) {
  const auto keys = m_values.keys();
  const auto new_keys = defaults.keys();
  m_values.setDefaults(defaults);
  emit valuesChangedInternally(keys + new_keys);
}

void StyleAgentGroup::whenValuesChangedInternally(
  const QStringList& keys) {
  const QSet<QString> changed_keys { keys.constBegin(),
    keys.constEnd() };

  for (const auto& key : changed_keys) {
    Qt::beginPropertyUpdateGroup();
    emit valueChanged(key);

#define CHECK_KEY(KEY)                                                 \
  if (key == #KEY)                                                     \
    emit KEY##Changed();
    CHECK_KEY(animationEnabled)
    CHECK_KEY(papaWords)

    QOOL_FOREACH_10(CHECK_KEY, window, windowText, base, alternateBase,
      toolTipBase, toolTipText, placeholderText, text, button,
      buttonText)
    QOOL_FOREACH_5(CHECK_KEY, light, midlight, dark, mid, shadow)
    QOOL_FOREACH_3(CHECK_KEY, highlight, accent, highlightedText)
    QOOL_FOREACH_2(CHECK_KEY, link, linkVisited)
    QOOL_FOREACH_3(CHECK_KEY, positive, negative, warning)

    QOOL_FOREACH_5(CHECK_KEY, windowCutSize, controlCutSize,
      menuCutSize, dialogCutSize, buttonCutSize)
    QOOL_FOREACH_2(CHECK_KEY, transitionDuration, movementDuration)
    QOOL_FOREACH_5(CHECK_KEY, titleTextSize, toolTipTextSize,
      controlTextSize, importantTextSize, decorativeTextSize)

#undef CHECK_KEY

    Qt::endPropertyUpdateGroup();
  }
}

#define IMPL(TYPE, NAME)                                               \
  TYPE StyleAgentGroup::NAME() const {                                 \
    if (m_values.contains(#NAME))                                      \
      return m_values.value<TYPE>(#NAME);                              \
    return StyleDB::instance()->anyValue(#NAME).value<TYPE>();         \
  }                                                                    \
  void StyleAgentGroup::set_##NAME(const TYPE& value) {                \
    const TYPE old = m_values.value<TYPE>(#NAME);                      \
    if (old == value)                                                  \
      return;                                                          \
    m_values.set_value<TYPE>(#NAME, value);                            \
    emit NAME##Changed();                                              \
    emit valueChanged(#NAME);                                          \
  }                                                                    \
  QBindable<TYPE> StyleAgentGroup::bindable_##NAME() {                 \
    return QBindable<TYPE>(this, #NAME);                               \
  }

IMPL(QStringList, papaWords)

#define IMPL_COLOR(NAME) IMPL(QColor, NAME)
QOOL_FOREACH_10(IMPL_COLOR, window, windowText, base, alternateBase,
  toolTipBase, toolTipText, placeholderText, text, button, buttonText)
QOOL_FOREACH_5(IMPL_COLOR, light, midlight, dark, mid, shadow)
QOOL_FOREACH_3(IMPL_COLOR, highlight, accent, highlightedText)
QOOL_FOREACH_2(IMPL_COLOR, link, linkVisited)
QOOL_FOREACH_3(IMPL_COLOR, positive, negative, warning)
#undef IMPL_COLOR

#define IMPL_REAL(NAME) IMPL(qreal, NAME)
QOOL_FOREACH_5(IMPL_REAL, windowCutSize, controlCutSize, menuCutSize,
  dialogCutSize, buttonCutSize)
QOOL_FOREACH_2(IMPL_REAL, transitionDuration, movementDuration)
#undef IMPL_REAL

#define IMPL_INT(NAME) IMPL(int, NAME)
QOOL_FOREACH_5(IMPL_INT, titleTextSize, toolTipTextSize,
  controlTextSize, importantTextSize, decorativeTextSize)
#undef IMPL_INT

#undef IMPL

QOOL_NS_END