#include "qool_octagonsettings.h"

QOOL_NS_BEGIN

OctagonSettings::OctagonSettings(QObject* parent)
  : QObject { parent } {
}

QString OctagonSettings::cutSizes() const {
  const QStringList sizes { QString::number(m_cutSizeTL.value()),
    QString::number(m_cutSizeTR.value()),
    QString::number(m_cutSizeBR.value()),
    QString::number(m_cutSizeBL.value()) };
  return sizes.join(' ');
}

void OctagonSettings::set_cutSizes(const QString& sizes) {
  const QStringList ss = sizes.split(' ', Qt::SkipEmptyParts);
  std::vector<qreal> numbers {};
  std::transform(ss.begin(), ss.end(), numbers.end(),
    [](const QString& x) { return x.toDouble(); });

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

QOOL_NS_END
