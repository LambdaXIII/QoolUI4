#ifndef QOOL_COLORLITERALS_H
#define QOOL_COLORLITERALS_H

#include "qoolns.hpp"
#include <QObject>
#include <QQmlEngine>
QOOL_NS_BEGIN

class ColorLiterals : public QObject {
  Q_OBJECT
  QML_ANONYMOUS

public:
  enum Channels {
    Alpha = 0,
    // RGB
    Red,
    Green,
    Blue,
    // HSV
    HSVHue,
    HSVSaturation,
    HSVValue,
    // HSL
    HSLHue,
    HSLSaturation,
    HSLLightness,
    // CMYK
    Cyan,
    Magenta,
    Yellow,
    Black
  };
  Q_ENUM(Channels)

  explicit ColorLiterals(QObject* parent = nullptr);

  Q_INVOKABLE static QString channelName(int channel);  // 属性名
  Q_INVOKABLE static QString channelNameF(int channel); // F系列属性名
  Q_INVOKABLE static QString channelTag(int channel);   // 外观标签文本
  Q_INVOKABLE static QString channelTagShort(int channel);
  Q_INVOKABLE static QColor channelColor(
      int channel); // transparent for undefined

  Q_INVOKABLE static QString formatChannelNumberFloat(
      qreal num); // 格式化归一化通道数值——四种输出：'0'/'1'/'.xxx'/'NaN'
  Q_INVOKABLE static qreal parseChannelNumberFloat(
      const QString& input); // 归一化通道值解析——清洗+头部补点（format 反向）
  Q_INVOKABLE static qreal clampChannelRange(qreal x);
};

QOOL_NS_END
#endif // QOOL_COLORLITERALS_H
