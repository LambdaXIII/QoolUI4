#ifndef QOOL_COLORLITERALS_H
#define QOOL_COLORLITERALS_H

#include "qoolcommon/qobject_property_macros.hpp"
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

  Q_INVOKABLE QString channelName(int channel) const;  // 属性名
  Q_INVOKABLE QString channelNameF(int channel) const; // F系列属性名
  Q_INVOKABLE QString channelTag(int channel) const;   // 外观标签文本

  Q_INVOKABLE static QString formatChannelNumberFloat(
      qreal num); // 格式化归一化通道数值

protected:
  static QHash<int, QString> m_channelNames;
  static QHash<int, QString> m_channelTags;
  QOBJECT_CONSTANT_PROPERTY_DECLARE(QVariantMap, channelNames)
  QOBJECT_CONSTANT_PROPERTY_DECLARE(QVariantMap, channelTags)
};

QOOL_NS_END
#endif // QOOL_COLORLITERALS_H
