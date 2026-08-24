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
// 丢弃）→ 无小数点时头部补一个（整数输入按纯小数解释：350 → ".350" →
// 0.35——对齐显示格式的无前导零约定）；**端点例外**："1"/"0" 对称还原
// 为 1.0/0.0（format 将端点输出为 "1"/"0"，不特判则编辑显示 "1" 收尾
// 会被补点误读为 ".1"，往返断裂）；失败（清洗后空/孤点）返回 NaN。
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

QOOL_NS_END
