#include "qool_octagonsettings.h"

#include "qoolcommon/debug.hpp"
#include "qoolcommon/macro_foreach.hpp"

#include <QRegularExpression>

QOOL_NS_BEGIN

OctagonSettings::OctagonSettings(QObject* parent)
  : QObject { parent } {
  m_cutSizes.fill(0);
  m_offsetX.setValue(0);
  m_offsetY.setValue(0);
  m_intOffsetX.setValue(0);
  m_intOffsetY.setValue(0);
  QOOL_PROPERTY_BINDABLE_INIT_VALUE(borderWidth, 0);
  QOOL_PROPERTY_BINDABLE_INIT_VALUE(borderColor, Qt::red);
  QOOL_PROPERTY_BINDABLE_INIT_VALUE(fillColor, Qt::yellow);

  connect(this, SIGNAL(cutSizesLockedChanged()), this,
    SLOT(notify_all_cutSizes_changed()));
}

void OctagonSettings::dumpInfo() const {
  xDebugQ << "Properties:" << xDBGQPropertyList;
}

void OctagonSettings::notify_all_cutSizes_changed() {
  Qt::beginPropertyUpdateGroup();
  emit cutSizeTLChanged();
  emit cutSizeTRChanged();
  emit cutSizeBLChanged();
  emit cutSizeBRChanged();
  Qt::endPropertyUpdateGroup();
}

void OctagonSettings::set_sizes(qreal x) {
  set_sizes(x, x, x, x);
}

void OctagonSettings::set_sizes(
  qreal tl, qreal tr, qreal br, qreal bl) {
  Qt::beginPropertyUpdateGroup();
  set_cutSizeTL(tl);
  set_cutSizeTR(tr);
  set_cutSizeBL(bl);
  set_cutSizeBR(br);
  Qt::endPropertyUpdateGroup();
}

void OctagonSettings::set_sizes(
  const std::vector<std::optional<qreal>>& numbers) {
  if (numbers.empty())
    return;

  if (numbers.size() == 1 && numbers[0].has_value()) {
    set_sizes(numbers[0].value());
    return;
  }

  Qt::beginPropertyUpdateGroup();
  if (numbers.size() > 0 && numbers[0].has_value())
    set_cutSizeTL(numbers[0].value());
  if (numbers.size() > 1 && numbers[1].has_value())
    set_cutSizeTR(numbers[1].value());
  if (numbers.size() > 2 && numbers[2].has_value())
    set_cutSizeBR(numbers[2].value());
  if (numbers.size() > 3 && numbers[3].has_value())
    set_cutSizeBL(numbers[3].value());
  Qt::endPropertyUpdateGroup();
}

void OctagonSettings::set_sizes(const QVariantList& list) {
  static const auto trans = [&](const QVariant& v) {
    if (v.canConvert<qreal>())
      return std::make_optional(v.toDouble());
    return std::optional<qreal>();
  };

  std::vector<std::optional<qreal>> numbers {};
  std::transform(list.constBegin(), list.constEnd(),
    std::back_inserter(numbers), trans);

  set_sizes(numbers);
}

void OctagonSettings::set_sizes(const QString& x) {
  static const QRegularExpression regex("\\d+(\\.\\d+)?");
  auto matches = regex.globalMatch(x);
  std::vector<std::optional<qreal>> numbers;
  while (matches.hasNext()) {
    const auto match = matches.next();
    const QString x = match.captured(0);
    std::optional<qreal> n = x.isNull() ?
                               std::optional<qreal>() :
                               std::make_optional(x.toDouble());
    numbers.push_back(n);
  }
  set_sizes(numbers);
}

QVariant OctagonSettings::cutSizes() const {
  static const auto all_equals = [&] {
    return m_cutSizes[0] == m_cutSizes[1]
           && m_cutSizes[0] == m_cutSizes[2]
           && m_cutSizes[0] == m_cutSizes[3];
  };

  if (m_cutSizesLocked || all_equals())
    return QVariant::fromValue<qreal>(cutSizeTL());

  QStringList sizes {};
  std::transform(m_cutSizes.cbegin(), m_cutSizes.cend(),
    std::back_inserter(sizes),
    [&](qreal x) { return QString::number(x); });
  return sizes.join(' ');
}

void OctagonSettings::set_cutSizes(const QVariant& sizes_var) {
  if (sizes_var.typeId() == QMetaType::Int
      || sizes_var.typeId() == QMetaType::Double) {
    const qreal x = sizes_var.toDouble();
    set_sizes(x);
    return;
  }

  if (sizes_var.typeId() == QMetaType::QStringList
      || sizes_var.typeId() == QMetaType::QVariantList) {
    const auto list = sizes_var.toList();
    set_sizes(list);
    return;
  }

  if (sizes_var.canConvert<QString>()) {
    const auto x = sizes_var.toString();
    set_sizes(x);
  }
}

bool OctagonSettings::cutSizesLocked() const {
  return m_cutSizesLocked;
}
void OctagonSettings::set_cutSizesLocked(const bool& x) {
  if (m_cutSizesLocked == x)
    return;
  m_cutSizesLocked = x;
  emit cutSizesLockedChanged();
}

constexpr int TL_INDEX = 0;
constexpr int TR_INDEX = 1;
constexpr int BR_INDEX = 2;
constexpr int BL_INDEX = 3;

#define IMPL(N)                                                        \
  qreal OctagonSettings::cutSize##N() const {                          \
    if (m_cutSizesLocked)                                              \
      return m_cutSizes[TL_INDEX];                                     \
    return m_cutSizes[N##_INDEX];                                      \
  }                                                                    \
  void OctagonSettings::set_cutSize##N(qreal x) {                      \
    const auto old = cutSize##N();                                     \
    if (old == x)                                                      \
      return;                                                          \
    m_cutSizes[N##_INDEX] = x;                                         \
    if (! m_cutSizesLocked)                                            \
      emit cutSize##N##Changed();                                      \
  }                                                                    \
  QBindable<qreal> OctagonSettings::bindable_cutSize##N() {            \
    return QBindable<qreal>(this, "cutSize" #N);                       \
  }

QOOL_FOREACH_3(IMPL, TR, BL, BR)

#undef IMPL

qreal OctagonSettings::cutSizeTL() const {
  return m_cutSizes[TL_INDEX];
}

void OctagonSettings::set_cutSizeTL(qreal x) {
  const auto old = cutSizeTL();
  if (old == x)
    return;
  m_cutSizes[TL_INDEX] = x;
  if (m_cutSizesLocked)
    notify_all_cutSizes_changed();
  else
    emit cutSizeTLChanged();
}

QBindable<qreal> OctagonSettings::bindable_cutSizeTL() {
  return QBindable<qreal>(this, "cutSizeTL");
}

QOOL_NS_END
