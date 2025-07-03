#include "qool_numberranger.h"

#include "qoolcommon/math/utils.hpp"

#include <QRegularExpression>

QOOL_NS_BEGIN

NumberRanger::NumberRanger(QObject* parent)
  : SmartObject { parent } {
  m_decimals.setValue(3);
  m_validated_top.setBinding([&] {
    std::optional<qreal> result;
    if (m_validateMode.value() == ValidateModes::IgnoreTop
        || m_validateMode.value() == ValidateModes::None)
      return result;
    if (m_top.value().isNull() || (! m_top.value().canConvert<qreal>()))
      return result;
    const int precision = m_decimals.value();
    const qreal top = m_top.value().value<qreal>();
    if (precision < 0)
      result.emplace(top);
    else if (precision == 0)
      result.emplace(std::round(top));
    else {
      const qreal r = math::set_precision(top, precision);
      result.emplace(r);
    }
    return result;
  });

  m_validated_bottom.setBinding([&] {
    std::optional<qreal> result;
    if (m_validateMode.value() == ValidateModes::IgnoreBottom
        || m_validateMode.value() == ValidateModes::None)
      return result;
    if (m_bottom.value().isNull()
        || (! m_bottom.value().canConvert<qreal>()))
      return result;
    const int precision = m_decimals.value();
    const qreal bottom = m_bottom.value().value<qreal>();
    if (precision < 0)
      result.emplace(bottom);
    else if (precision == 0)
      result.emplace(std::round(bottom));
    else {
      const qreal r = math::set_precision(bottom, precision);
      result.emplace(r);
    }
    return result;
  });

  setup_tracking_numbers();
}

QVariant NumberRanger::validate(const QVariant& number) const {
  if (number.isNull())
    return number;
  if (! number.canConvert<qreal>())
    return number;
  const qreal n = decimalfy(number.toDouble());
  if (m_validated_top.value().has_value()) {
    const auto t = m_validated_top.value().value();
    if (n > t)
      return { t };
  }
  if (m_validated_bottom.value().has_value()) {
    const auto b = m_validated_bottom.value().value();
    if (n < b)
      return { b };
  }
  return { n };
}

QVariant NumberRanger::validatePrecision(const QVariant& number) const {
  if (number.isNull() || ! number.canConvert<qreal>())
    return number;
  const qreal n = number.value<qreal>();
  return { decimalfy(n) };
}

QVariant NumberRanger::format(const QVariant& v) const {
  if (v.isNull())
    return v;

  if (v.canConvert<qreal>())
    return QString::number(decimalfy(v.value<qreal>()));

  if (v.canConvert<QString>()) {
    auto str = v.toString();
    static const QRegularExpression regex("\\d+(\\.\\d+)?");
    QMap<QString, QString> replacements;
    QRegularExpressionMatchIterator i = regex.globalMatch(str);
    while (i.hasNext()) {
      const auto a = i.next().captured(0);
      const qreal n = decimalfy(a.toDouble());
      const auto b = QString::number(n, 'g', m_decimals.value());
      replacements.insert(a, b);
    }
    for (auto rep = replacements.constBegin();
      rep != replacements.constEnd();
      ++rep) {
      str.replace(rep.key(), rep.value());
    }
    return str;
  }
  return v;
}

qreal NumberRanger::decimalfy(qreal x) const {
  const int d = m_decimals.value();
  if (d < 0)
    return x;
  if (d == 0)
    return std::round(x);
  return math::set_precision(x, d);
}

void NumberRanger::setup_tracking_numbers() {
#define GET_V(N)                                                       \
  if (m_input##N.value().isNull()                                      \
      || ! m_input##N.value().canConvert<qreal>())                     \
    return m_input##N.value();                                         \
  const qreal v = decimalfy(m_input##N.value().value<qreal>());        \
  if (m_validated_top.value().has_value()) {                           \
    const auto top = m_validated_top.value().value();                  \
    if (v > top)                                                       \
      return QVariant(top);                                            \
  }                                                                    \
  if (m_validated_bottom.value().has_value()) {                        \
    const auto bottom = m_validated_bottom.value().value();            \
    if (v < bottom)                                                    \
      return QVariant(bottom);                                         \
  }                                                                    \
  return QVariant(v);
#define SETUP(N) m_validated##N.setBinding([&] { GET_V(N) });
  QOOL_FOREACH_10(SETUP, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9)
#undef SETUP
#undef GET_V
}

QOOL_NS_END
