#include "qool_colorliterals.h"
#include "qoolcommon/math.hpp"
#include <QMutex>
#include <QtMath>
#include <cmath>
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

// 格式化归一化通道数值：刻意仅四种输出——'0'、'1'、'.xxx'（三位小数无
// 前导零）、'NaN'。round 到 1000（≥0.9995）归 '1'、round 到 0 归 '0'
// （千分位边界：不进位到 1000 后取模归零）。
QString ColorLiterals::formatChannelNumberFloat(qreal num) {
  if (std::isnan(num)) return QStringLiteral("NaN");
  if (math::is_zero(num)) return QStringLiteral("0");
  if (math::is_equal(num, 1.0)) return QStringLiteral("1");
  int a = int(std::round(num * 1000.0));
  if (a >= 1000) return QStringLiteral("1");
  if (a <= 0) return QStringLiteral("0");
  return QString(".%1").arg(a);
}

// 解析归一化通道值（formatChannelNumberFloat 的反向——format 输出可解析
// 回原值）：清洗输入（仅保留数字与第一个小数点，其余字符/后续小数点
// 丢弃）→ 无小数点在头部补一个（整数输入按纯小数解释：350 → ".350" →
// 0.35——对齐显示格式的无前导零约定）→ 解析数字；失败（清洗后空/孤点）
// 返回 NaN。
qreal ColorLiterals::parseChannelNumberFloat(const QString& input) {
  QString cleaned;
  bool dotSeen = false;
  for (QChar c : input) {
    if (c.isDigit()) {
      cleaned.append(c);
    } else if (c == QLatin1Char('.') && !dotSeen) {
      cleaned.append(c);
      dotSeen = true;
    }
  }
  if (!dotSeen)
    cleaned.prepend(QLatin1Char('.'));
  bool ok = false;
  qreal v = cleaned.toDouble(&ok);
  return ok ? v : qQNaN();
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
