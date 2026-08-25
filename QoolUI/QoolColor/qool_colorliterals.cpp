#include "qool_colorliterals.h"
#include "qoolcommon/math.hpp"
#include <QColor>
#include <QMutex>
#include <QtMath>
#include <cmath>

QOOLCOMMON_MATH_MARK

QOOL_NS_BEGIN

QHash<int, QString> __channelNames{

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

QHash<int, std::pair<QString, QString>> __channelTags{

#define TAG(NN, SS, LL)                                             \
  {                                                                 \
    ColorLiterals::NN, { QStringLiteral(#SS), QStringLiteral(#LL) } \
  }

  TAG(Alpha, ALFA, ALPHA),

  TAG(Red, RED, RED), TAG(Green, GRIN, GREEN), TAG(Blue, BLUE, BLUE),

  TAG(HSVHue, HUE, HUE), TAG(HSVSaturation, SAT, SATURATION),
  TAG(HSVValue, BRIT, VALUE), // 短标签 BRIT 刻意 4 字母缩写（旧面板标题），勿"修正"

  TAG(HSLHue, HUE, HUE), TAG(HSLSaturation, SAT, SATURATION),
  TAG(HSLLightness, LIT, LIGHTNESS),

  TAG(Cyan, CYAN, CYAN), TAG(Magenta, MAGT, MAGENTA), TAG(Yellow, YELO, YELLOW),
  TAG(Black, BLAK, BLAK)

#undef TAG

};

ColorLiterals::ColorLiterals(QObject* parent)
  : QObject{parent} { }

QString ColorLiterals::channelName(int channel) {
  return __channelNames[channel];
}

QString ColorLiterals::channelNameF(int channel) {
  QString result{channelName(channel)};
  result.append('F');
  return result;
}

QString ColorLiterals::channelTag(int channel) {
  return __channelTags.value(channel, {"???", "???"}).second;
}

QString ColorLiterals::channelTagShort(int channel) {
  return __channelTags.value(channel, {"???", "???"}).first;
}

QColor ColorLiterals::channelColor(int channel) {

  static QHash<int, QColor> colors{
#define SC(NN, CC) {ColorLiterals::NN, Qt::CC}
    SC(Alpha, gray),
    SC(Red, red),
    SC(Green, green),
    SC(Blue, blue),
    SC(HSVValue, lightGray),
    SC(HSLLightness, lightGray),
    SC(Cyan, cyan),
    SC(Magenta, magenta),
    SC(Yellow, yellow),
    SC(Black, darkGray),
#undef SC
  };

  return colors.value(channel, Qt::transparent);
}

// 仅四种输出：'0'、'1'、'.xxx'（三位小数无前导零）、'NaN'。
QString ColorLiterals::formatChannelNumberFloat(qreal num) {
  if (std::isnan(num)) return QStringLiteral("NaN");
  if (math::is_zero(num)) return QStringLiteral("0");
  if (math::is_equal(num, 1.0)) return QStringLiteral("1");
  int a = int(std::round(num * 1000.0));
  if (a >= 1000) return QStringLiteral("1");
  if (a <= 0) return QStringLiteral("0");
  return QString(".%1").arg(a);
}

// 清洗+补点（整数按纯小数解释：350→.350）；端点 "1"/"0" 对称还原（format
// 端点折叠串，不特判则往返断裂）；清洗后空/孤点返回 NaN。
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
  if (!dotSeen) {
    if (cleaned == QLatin1String("1"))
      return 1.0;
    if (cleaned == QLatin1String("0"))
      return 0.0;
    cleaned.prepend(QLatin1Char('.'));
  }
  bool ok = false;
  qreal v = cleaned.toDouble(&ok);
  return ok ? v : qQNaN();
}

qreal ColorLiterals::clampChannelRange(qreal x) {
  return math::auto_bound(0.0, x, 1.0);
}

qreal ColorLiterals::visualBrightness(const QColor& color) {
  const auto c = color.toRgb();
  return c.redF() * 0.299 + c.greenF() * 0.587 + c.blueF() * 0.114;
}

QColor ColorLiterals::keepItDark(const QColor& color) {
  const auto original = color.toHsv();
  const auto new_value = std::min<qreal>(0.65, color.valueF());
  return QColor::fromHsvF(
      original.hueF(), original.saturationF(), new_value, original.alphaF());
}

QColor ColorLiterals::keepItBright(const QColor& color) {
  const auto original = color.toHsv();
  const auto new_value = std::max<qreal>(0.25, color.valueF());
  return QColor::fromHsvF(
      original.hueF(), original.saturationF(), new_value, original.alphaF());
}

QOOL_NS_END
