#ifndef QOOL_COLORASSISTANT_H
#define QOOL_COLORASSISTANT_H

#include "qoolns.hpp"

#include "qool_colorliterals.h"
#include <QColor>
#include <QList>
#include <QObject>
#include <QQmlEngine>
#include <QString>
QOOL_NS_BEGIN

// 局部宏：分量属性（int/F 双轨）——Q_PROPERTY 注册 + getter/setter/信号声明 + 成员。
// 本类属性手写 Q_PROPERTY 而非宏体系（AGENTS「例外」条款）：每个分量 setter
// 有自定义语义（分量 → set_color 全空间重算 → 全信号），宏体系 setter 为纯
// 赋值不适用；且派生只读属性共用 colorChanged（多属性共享同一信号）。
// 手写属性必须注册 Q_PROPERTY：漏注册不产生编译错误，QML 侧读取得
// undefined、写入被丢弃（面板分量输入为空、光标坐标 NaN 等故障）。
#define XX_PROP_DECLARE(_T_, _N_)                \
public:                                          \
  Q_SIGNAL void _N_##Changed();                  \
  _T_ _N_() const;                               \
  void set_##_N_(_T_ new_##_N_);                 \
                                                 \
protected:                                       \
  Q_PROPERTY(_T_ _N_ READ _N_ WRITE set_##_N_    \
      NOTIFY _N_##Changed)                       \
  void update_##_N_(const _T_& x);               \
  _T_ m_##_N_{ 0 };

class ColorAssistant : public QObject {
  Q_OBJECT
  QML_ELEMENT

  // ---- 核心与列表属性 ----
  Q_PROPERTY(QColor color READ color WRITE set_color NOTIFY colorChanged)
  Q_PROPERTY(QList<qreal> rgbaF READ rgbaF WRITE set_rgbaF NOTIFY rgbaFChanged)
  Q_PROPERTY(QList<qreal> cmykF READ cmykF WRITE set_cmykF NOTIFY cmykFChanged)
  Q_PROPERTY(QList<qreal> hsvF READ hsvF WRITE set_hsvF NOTIFY hsvFChanged)
  Q_PROPERTY(QList<qreal> hslF READ hslF WRITE set_hslF NOTIFY hslFChanged)
  Q_PROPERTY(QList<int> rgba READ rgba WRITE set_rgba NOTIFY rgbaChanged)
  Q_PROPERTY(QList<int> cmyk READ cmyk WRITE set_cmyk NOTIFY cmykChanged)
  Q_PROPERTY(QList<int> hsv READ hsv WRITE set_hsv NOTIFY hsvChanged)
  Q_PROPERTY(QList<int> hsl READ hsl WRITE set_hsl NOTIFY hslChanged)
  Q_PROPERTY(QString name READ name WRITE set_name NOTIFY nameChanged)

  // ---- 派生只读属性（共用 colorChanged）----
  Q_PROPERTY(QColor solidColor READ solidColor NOTIFY colorChanged)
  Q_PROPERTY(qreal visualBrightness READ visualBrightness NOTIFY colorChanged)
  Q_PROPERTY(QColor recommendedForegroundColor READ recommendedForegroundColor
      NOTIFY colorChanged)

  // ---- 分量属性（int/F 双轨）----
  XX_PROP_DECLARE(qreal, redF)
  XX_PROP_DECLARE(qreal, greenF)
  XX_PROP_DECLARE(qreal, blueF)
  XX_PROP_DECLARE(qreal, alphaF)
  XX_PROP_DECLARE(int, red)
  XX_PROP_DECLARE(int, green)
  XX_PROP_DECLARE(int, blue)
  XX_PROP_DECLARE(int, alpha)

  XX_PROP_DECLARE(qreal, cyanF)
  XX_PROP_DECLARE(qreal, magentaF)
  XX_PROP_DECLARE(qreal, yellowF)
  XX_PROP_DECLARE(qreal, blackF)
  XX_PROP_DECLARE(int, cyan)
  XX_PROP_DECLARE(int, magenta)
  XX_PROP_DECLARE(int, yellow)
  XX_PROP_DECLARE(int, black)

  XX_PROP_DECLARE(qreal, hsvHueF)
  XX_PROP_DECLARE(qreal, hsvSaturationF)
  XX_PROP_DECLARE(qreal, hsvValueF)
  XX_PROP_DECLARE(int, hsvHue)
  XX_PROP_DECLARE(int, hsvSaturation)
  XX_PROP_DECLARE(int, hsvValue)

  XX_PROP_DECLARE(qreal, hslHueF)
  XX_PROP_DECLARE(qreal, hslSaturationF)
  XX_PROP_DECLARE(qreal, hslLightnessF)
  XX_PROP_DECLARE(int, hslHue)
  XX_PROP_DECLARE(int, hslSaturation)
  XX_PROP_DECLARE(int, hslLightness)

public:
  explicit ColorAssistant(QObject* parent = nullptr);

  Q_INVOKABLE static QString hex(int number);
  Q_INVOKABLE static bool isValidName(const QString& name);
  Q_INVOKABLE bool isValid() const;

  QColor color() const;
  void set_color(QColor color);

  // ---- 列表属性（动态组装，无成员）----
  QList<qreal> rgbaF() const;
  void set_rgbaF(QList<qreal> xs);
  QList<qreal> cmykF() const;
  void set_cmykF(QList<qreal> xs);
  QList<qreal> hsvF() const;
  void set_hsvF(QList<qreal> xs);
  QList<qreal> hslF() const;
  void set_hslF(QList<qreal> xs);
  QList<int> rgba() const;
  void set_rgba(QList<int> xs);
  QList<int> cmyk() const;
  void set_cmyk(QList<int> xs);
  QList<int> hsv() const;
  void set_hsv(QList<int> xs);
  QList<int> hsl() const;
  void set_hsl(QList<int> xs);

  // ---- name（动态生成，无成员）----
  QString name() const;
  void set_name(QString n);

  // ---- 派生只读 ----
  QColor solidColor() const;
  qreal visualBrightness() const;
  QColor recommendedForegroundColor() const;

Q_SIGNALS:
  void colorChanged();
  void rgbaFChanged();
  void cmykFChanged();
  void hsvFChanged();
  void hslFChanged();
  void rgbaChanged();
  void cmykChanged();
  void hsvChanged();
  void hslChanged();
  void nameChanged();

private:
  QColor m_color;
};

#undef XX_PROP_DECLARE

QOOL_NS_END

#endif // QOOL_COLORASSISTANT_H
