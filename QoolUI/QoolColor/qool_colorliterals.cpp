#include "qool_colorliterals.h"
#include "qoolcommon/math.hpp"
#include <QMutex>
QOOLCOMMON_MATH_MARK
QOOL_NS_BEGIN

QHash<int, QString> ColorLiterals::m_channelNames{

#define NAME(AA, BB) {ColorLiterals::AA, QStringLiteral(#BB)}

  NAME(Alpha, alpha),

  NAME(Red, red), NAME(Green, green), NAME(Blue, blue),

  NAME(HSVHue, hsvHue), NAME(HSVSaturation, hsvSaturation),
  NAME(HSVValue, hsvValue),

  NAME(HSLHue, hslHue), NAME(HSLSaturation, hslSaturation),
  NAME(HSLLightness, hslLightness),

  NAME(Cyan, cyan), NAME(Magenta, magenta), NAME(Yellow, yellow),
  NAME(Black, black)

#undef NAME

};

QHash<int, QString> ColorLiterals::m_channelTags{

#define NAME(AA, BB) {ColorLiterals::AA, QStringLiteral(#BB)}

  NAME(Alpha, ALPHA),

  NAME(Red, RED), NAME(Green, GREEN), NAME(Blue, BLUE),

  NAME(HSVHue, HUE), NAME(HSVSaturation, SATURATION), NAME(HSVValue, VALUE),

  NAME(HSLHue, HUE), NAME(HSLSaturation, SATURATION),
  NAME(HSLLightness, LIGHTNESS),

  NAME(Cyan, CYAN), NAME(Magenta, MAGT), NAME(Yellow, YELO), NAME(Black, BLAK)

#undef NAME

};

ColorLiterals::ColorLiterals(QObject* parent)
  : QObject{parent} { }

QString ColorLiterals::channelName(int channel) const {
  return m_channelNames[channel];
}

QString ColorLiterals::channelNameF(int channel) const {
  QString result{channelName(channel)};
  result.append('F');
  return result;
}

QString ColorLiterals::channelTag(int channel) const {
  return m_channelTags.value(channel, "???");
}

QString ColorLiterals::formatChannelNumberFloat(qreal num) {
  if (math::is_zero(num)) return QStringLiteral("0");
  if (math::is_equal(num, 1.0)) return QStringLiteral("1");
  int a = int(std::round(num * 1000.0)) % 1000;
  return QString(".%1").arg(a);
}

void __variantify_string_hash(
    QVariantMap& to, const QHash<int, QString>& from) {
  for (const auto& [k, v] : from.asKeyValueRange())
    to[QString::number(k)] = v;
}

QVariantMap ColorLiterals::channelNames() const {

  static QMutex mutex;
  static QVariantMap names;

  if (names.isEmpty()) {
    QMutexLocker locker(&mutex);
    if (names.isEmpty()) __variantify_string_hash(names, m_channelNames);
  }

  return names;
}

QVariantMap ColorLiterals::channelTags() const {

  static QMutex mutex;
  static QVariantMap tags;

  if (tags.isEmpty()) {
    QMutexLocker locker(&mutex);
    if (tags.isEmpty()) __variantify_string_hash(tags, m_channelTags);
  }

  return tags;
}

QOOL_NS_END
