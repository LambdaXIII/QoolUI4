#include "qool_qoolbox_settings.h"

#include "qoolcommon/debug.hpp"

#include <QRegularExpression>

QOOL_NS_BEGIN

QoolBoxSettings::QoolBoxSettings(QObject* parent)
  : QObject { parent } {
  QOOL_PROPERTY_BINDABLE_INIT_VALUE(offsetX, 0);
  QOOL_PROPERTY_BINDABLE_INIT_VALUE(offsetY, 0);
  QOOL_PROPERTY_BINDABLE_INIT_VALUE(intOffsetX, 0);
  QOOL_PROPERTY_BINDABLE_INIT_VALUE(intOffsetY, 0);
  QOOL_PROPERTY_BINDABLE_INIT_VALUE(borderWidth, 0);
  QOOL_PROPERTY_BINDABLE_INIT_VALUE(borderColor, Qt::red);
  QOOL_PROPERTY_BINDABLE_INIT_VALUE(fillColor, Qt::yellow);

  m_isAllCutSizesEquals.setBinding([&] {
    const auto tl = m_cutSizeTL.value();
    const auto tr = m_cutSizeTR.value();
    const auto bl = m_cutSizeBL.value();
    const auto br = m_cutSizeBR.value();
    return tl == tr && tl == bl && tl == br;
  });
}

void QoolBoxSettings::dumpInfo() const {
  xDebugQ << "Properties:" << xDBGQPropertyList;
}

void QoolBoxSettings::set_sizes(qreal x) {
  set_sizes(x, x, x, x);
}

void QoolBoxSettings::set_sizes(
  qreal tl, qreal tr, qreal br, qreal bl) {
  Qt::beginPropertyUpdateGroup();
  remove_cutSize_bindings();
  m_cutSizeTL.setValue(tl);
  m_cutSizeTR.setValue(tr);
  m_cutSizeBL.setValue(bl);
  m_cutSizeBR.setValue(br);
  Qt::endPropertyUpdateGroup();
}

void QoolBoxSettings::set_sizes(
  const std::vector<std::optional<qreal>>& numbers) {
  if (numbers.empty())
    return;

  if (numbers.size() == 1 && numbers[0].has_value()) {
    set_sizes(numbers[0].value());
    return;
  }

  Qt::beginPropertyUpdateGroup();
  remove_cutSize_bindings();
  if (numbers.size() > 0 && numbers[0].has_value())
    m_cutSizeTL.setValue(numbers[0].value());
  if (numbers.size() > 1 && numbers[1].has_value())
    m_cutSizeTR.setValue(numbers[1].value());
  if (numbers.size() > 2 && numbers[2].has_value())
    m_cutSizeBR.setValue(numbers[2].value());
  if (numbers.size() > 3 && numbers[3].has_value())
    m_cutSizeBL.setValue(numbers[3].value());
  Qt::endPropertyUpdateGroup();
}

void QoolBoxSettings::set_sizes(const QVariantList& list) {
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

void QoolBoxSettings::set_sizes(const QString& x) {
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

void QoolBoxSettings::remove_cutSize_bindings() {
  m_cutSizeTL.takeBinding();
  m_cutSizeTR.takeBinding();
  m_cutSizeBL.takeBinding();
  m_cutSizeBR.takeBinding();
}

QVariant QoolBoxSettings::cutSizes() const {
  const auto all_equals = m_isAllCutSizesEquals.value();
  if (all_equals)
    return QVariant::fromValue<qreal>(cutSizeTL());

  QStringList sizes;
  sizes << QString::number(cutSizeTL()) << QString::number(cutSizeTR())
        << QString::number(cutSizeBR()) << QString::number(cutSizeBL());
  return sizes.join(' ');
}

void QoolBoxSettings::set_cutSizes(const QVariant& sizes_var) {
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

QOOL_NS_END
