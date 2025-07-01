#include "qool_octagonsettings.h"

#include "qoolcommon/debug.hpp"

QOOL_NS_BEGIN

OctagonSettings::OctagonSettings(QObject* parent)
  : QObject { parent } {
  QOOL_PROPERTY_BINDABLE_INIT_VALUE(cutSizeTL, 0);
  QOOL_PROPERTY_BINDABLE_INIT_VALUE(cutSizeTR, 0);
  QOOL_PROPERTY_BINDABLE_INIT_VALUE(cutSizeBL, 0);
  QOOL_PROPERTY_BINDABLE_INIT_VALUE(cutSizeBR, 0);
  QOOL_PROPERTY_BINDABLE_INIT_VALUE(borderWidth, 0);
  QOOL_PROPERTY_BINDABLE_INIT_VALUE(borderColor, Qt::red);
  QOOL_PROPERTY_BINDABLE_INIT_VALUE(fillColor, Qt::yellow);
}

void OctagonSettings::dumpInfo() const {
  xDebugQ << "Properties:" << xDBGQPropertyList;
}

QString OctagonSettings::cutSizes() const {
  const std::array<qreal, 4> numbers({ m_cutSizeTL.value(),
    m_cutSizeTR.value(), m_cutSizeBR.value(), m_cutSizeBL.value() });

  const std::set<qreal> the_set(numbers.cbegin(), numbers.cend());
  if (the_set.size() == 1)
    return QString::number(numbers.at(0));

  QStringList sizes {};
  std::transform(numbers.begin(), numbers.end(),
    std::back_inserter(sizes),
    [&](qreal x) { return QString::number(x); });
  return sizes.join(' ');
}

void OctagonSettings::set_cutSizes(const QString& sizes) {
  const QStringList ss = sizes.split(' ', Qt::SkipEmptyParts);
  std::vector<qreal> numbers {};
  std::transform(ss.begin(), ss.end(), std::back_inserter(numbers),
    [](const QString& x) { return x.toDouble(); });

  if (numbers.size() == 1) {
    Qt::beginPropertyUpdateGroup();
    const auto a = numbers.at(0);
    set_cutSizeTL(a);
    set_cutSizeTR(a);
    set_cutSizeBL(a);
    set_cutSizeBR(a);
    Qt::endPropertyUpdateGroup();
  } else {
    Qt::beginPropertyUpdateGroup();
    for (int i = 0; i < numbers.size(); i++) {
      switch (i) {
      case 0:
        set_cutSizeTL(numbers.at(i));
        break;
      case 1:
        set_cutSizeTR(numbers.at(i));
        break;
      case 2:
        set_cutSizeBR(numbers.at(i));
        break;
      case 3:
        set_cutSizeBL(numbers.at(i));
        break;
      default:
        break;
      }
    }
    Qt::endPropertyUpdateGroup();
  }
}

QOOL_NS_END
