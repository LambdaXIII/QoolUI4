#include "qool_colorassistant.h"

#include "qoolcommon/debug.hpp"

QOOL_NS_BEGIN

ColorAssistant::ColorAssistant(QObject* parent)
  : QObject { parent } {
}

// hex：整数转十六进制字符串（# 前缀由调用方自行处理）。
QString ColorAssistant::hex(int number) {
  return QString::number(number, 16);
}

// isValidName：是否合法颜色名（CSS 色名或 #RRGGBB/#AARRGGBB 形式）。
bool ColorAssistant::isValidName(const QString& name) {
  return QColor::isValidColorName(name);
}

// isValid：当前颜色是否有效（未设置过有效颜色时为 false）。
bool ColorAssistant::isValid() const {
  return m_color.isValid();
}

QColor ColorAssistant::color() const {
  return m_color;
}

// 统一颜色入口：任一分量/列表/name setter 最终都经此重算全空间并广播信号。
// 值未变化时不广播（相等守卫，Changed 语义 = 值实际变化才发出）。
void ColorAssistant::set_color(QColor color) {
  if (m_color == color)
    return;

  if (!color.isValid())
    xDebugQ << tr("设置了非法的色彩：") << color;

  m_color = color;

  QColor c = m_color.toRgb();
  update_redF(c.redF());
  update_red(c.red());
  update_greenF(c.greenF());
  update_green(c.green());
  update_blueF(c.blueF());
  update_blue(c.blue());

  update_alphaF(c.alphaF());
  update_alpha(c.alpha());

  c = c.toHsv();
  update_hsvHueF(c.hsvHueF());
  update_hsvSaturationF(c.hsvSaturationF());
  update_hsvValueF(c.valueF());
  update_hsvHue(c.hsvHue());
  update_hsvSaturation(c.hsvSaturation());
  update_hsvValue(c.value());

  c = c.toHsl();
  update_hslHueF(c.hslHueF());
  update_hslSaturationF(c.hslSaturationF());
  update_hslLightnessF(c.lightnessF());
  update_hslHue(c.hslHue());
  update_hslSaturation(c.saturation());
  update_hslLightness(c.lightness());

  c = c.toCmyk();
  update_cyanF(c.cyanF());
  update_cyan(c.cyan());
  update_magentaF(c.magentaF());
  update_magenta(c.magenta());
  update_yellowF(c.yellowF());
  update_yellow(c.yellow());
  update_blackF(c.blackF());
  update_black(c.black());

  emit nameChanged();
  emit rgbaChanged();
  emit rgbaFChanged();
  emit cmykChanged();
  emit cmykFChanged();
  emit hsvChanged();
  emit hsvFChanged();
  emit hslChanged();
  emit hslFChanged();

  emit colorChanged();
}

// solidColor：去 alpha 的纯色版本（alpha 强制 1）。
QColor ColorAssistant::solidColor() const {
  auto c = m_color;
  c.setAlphaF(1);
  return c;
}

// visualBrightness：感知亮度（0.299/0.587/0.114 加权），公式与 ThemeHQ 一致；
// ThemeDB 的 C++ 符号不导出（v4 原则），故此处自实现。
qreal ColorAssistant::visualBrightness() const {
  const auto c = m_color.toRgb();
  return c.redF() * 0.299 + c.greenF() * 0.587 + c.blueF() * 0.114;
}

// recommendedForegroundColor：对比前景色（亮度 ≥0.5 → 黑，否则白），
// 与 ThemeHQ.recommendForeground 语义等价（阈值 0.5）。
QColor ColorAssistant::recommendedForegroundColor() const {
  const auto b = visualBrightness();
  return b >= 0.5 ? Qt::black : Qt::white;
}

// ---- 列表属性（动态组装，无成员）----

QList<qreal> ColorAssistant::rgbaF() const {
  return { redF(), greenF(), blueF(), alphaF() };
}

void ColorAssistant::set_rgbaF(QList<qreal> xs) {
  if (xs == rgbaF())
    return;
  auto c = m_color.toRgb();
  auto r = xs.value(0, c.redF());
  auto g = xs.value(1, c.greenF());
  auto b = xs.value(2, c.blueF());
  auto a = xs.value(3, c.alphaF());
  QColor res = QColor::fromRgbF(r, g, b, a);
  set_color(res);
}

QList<qreal> ColorAssistant::cmykF() const {
  return { cyanF(), magentaF(), yellowF(), blackF() };
}

void ColorAssistant::set_cmykF(QList<qreal> xs) {
  if (xs == cmykF())
    return;
  auto color = m_color.toCmyk();
  auto c = xs.value(0, color.cyanF());
  auto m = xs.value(1, color.magentaF());
  auto y = xs.value(2, color.yellowF());
  auto k = xs.value(3, color.blackF());
  QColor res = QColor::fromCmykF(c, m, y, k);
  res.setAlphaF(color.alphaF());
  set_color(res);
}

QList<qreal> ColorAssistant::hsvF() const {
  return { hsvHueF(), hsvSaturationF(), hsvValueF() };
}

void ColorAssistant::set_hsvF(QList<qreal> xs) {
  if (xs == hsvF())
    return;
  auto color = m_color.toHsv();
  auto h = xs.value(0, color.hsvHueF());
  auto s = xs.value(1, color.hsvSaturationF());
  auto v = xs.value(2, color.valueF());
  QColor res = QColor::fromHsvF(h, s, v);
  res.setAlphaF(color.alphaF());
  set_color(res);
}

QList<qreal> ColorAssistant::hslF() const {
  return { hslHueF(), hslSaturationF(), hslLightnessF() };
}

void ColorAssistant::set_hslF(QList<qreal> xs) {
  if (xs == hslF())
    return;
  auto color = m_color.toHsl();
  auto h = xs.value(0, color.hslHueF());
  auto s = xs.value(1, color.hslSaturationF());
  auto l = xs.value(2, color.lightnessF());
  QColor res = QColor::fromHslF(h, s, l);
  res.setAlphaF(color.alphaF());
  set_color(res);
}

QList<int> ColorAssistant::rgba() const {
  return { red(), green(), blue(), alpha() };
}

void ColorAssistant::set_rgba(QList<int> xs) {
  if (xs == rgba())
    return;
  auto c = m_color.toRgb();
  auto r = xs.value(0, c.red());
  auto g = xs.value(1, c.green());
  auto b = xs.value(2, c.blue());
  auto a = xs.value(3, c.alpha());
  QColor res = QColor::fromRgb(r, g, b, a);
  set_color(res);
}

QList<int> ColorAssistant::cmyk() const {
  return { cyan(), magenta(), yellow(), black() };
}

void ColorAssistant::set_cmyk(QList<int> xs) {
  if (xs == cmyk())
    return;
  auto color = m_color.toCmyk();
  auto c = xs.value(0, color.cyan());
  auto m = xs.value(1, color.magenta());
  auto y = xs.value(2, color.yellow());
  auto k = xs.value(3, color.black());
  QColor res = QColor::fromCmyk(c, m, y, k);
  res.setAlpha(color.alpha());
  set_color(res);
}

QList<int> ColorAssistant::hsv() const {
  return { hsvHue(), hsvSaturation(), hsvValue() };
}

void ColorAssistant::set_hsv(QList<int> xs) {
  if (xs == hsv())
    return;
  auto color = m_color.toHsv();
  auto h = xs.value(0, color.hsvHue());
  auto s = xs.value(1, color.hsvSaturation());
  auto v = xs.value(2, color.value());
  QColor res = QColor::fromHsv(h, s, v);
  res.setAlpha(color.alpha());
  set_color(res);
}

QList<int> ColorAssistant::hsl() const {
  return { hslHue(), hslSaturation(), hslLightness() };
}

void ColorAssistant::set_hsl(QList<int> xs) {
  if (xs == hsl())
    return;
  auto color = m_color.toHsl();
  auto h = xs.value(0, color.hslHue());
  auto s = xs.value(1, color.hslSaturation());
  auto l = xs.value(2, color.lightness());
  QColor res = QColor::fromHsl(h, s, l);
  res.setAlpha(color.alpha());
  set_color(res);
}

// ---- name（动态生成：不透明时 #AARRGGBB，否则 #RRGGBB）----

QString ColorAssistant::name() const {
  if (m_alphaF < 1)
    return m_color.name(QColor::HexArgb);
  return m_color.name(QColor::HexRgb);
}

void ColorAssistant::set_name(QString n) {
  QColor c = QColor::fromString(n);
  if (m_color == c)
    return;
  set_color(c);
}

// ---- 分量 setter（各自空间改分量 → 统一入口全空间重算）----

void ColorAssistant::set_redF(qreal new_redF) {
  if (new_redF == redF())
    return;
  QColor c = m_color.toRgb();
  c.setRedF(new_redF);
  set_color(c);
}

void ColorAssistant::set_greenF(qreal new_greenF) {
  if (new_greenF == greenF())
    return;
  QColor c = m_color.toRgb();
  c.setGreenF(new_greenF);
  set_color(c);
}

void ColorAssistant::set_blueF(qreal new_blueF) {
  if (new_blueF == blueF())
    return;
  QColor c = m_color.toRgb();
  c.setBlueF(new_blueF);
  set_color(c);
}

void ColorAssistant::set_alphaF(qreal new_alphaF) {
  if (new_alphaF == alphaF())
    return;
  QColor c = m_color.toRgb();
  c.setAlphaF(new_alphaF);
  set_color(c);
}

void ColorAssistant::set_red(int new_red) {
  if (new_red == red())
    return;
  QColor c = m_color.toRgb();
  c.setRed(new_red);
  set_color(c);
}

void ColorAssistant::set_green(int new_green) {
  if (new_green == green())
    return;
  QColor c = m_color.toRgb();
  c.setGreen(new_green);
  set_color(c);
}

void ColorAssistant::set_blue(int new_blue) {
  if (new_blue == blue())
    return;
  QColor c = m_color.toRgb();
  c.setBlue(new_blue);
  set_color(c);
}

void ColorAssistant::set_alpha(int new_alpha) {
  if (new_alpha == alpha())
    return;
  QColor c = m_color.toRgb();
  c.setAlpha(new_alpha);
  set_color(c);
}

void ColorAssistant::set_cyanF(qreal new_cyanF) {
  if (new_cyanF == cyanF())
    return;
  QColor c = m_color.toCmyk();
  c.setCmykF(new_cyanF, c.magentaF(), c.yellowF(), c.blackF(), c.alphaF());
  set_color(c);
}

void ColorAssistant::set_magentaF(qreal new_magentaF) {
  if (new_magentaF == magentaF())
    return;
  QColor c = m_color.toCmyk();
  c.setCmykF(c.cyanF(), new_magentaF, c.yellowF(), c.blackF(), c.alphaF());
  set_color(c);
}

void ColorAssistant::set_yellowF(qreal new_yellowF) {
  if (new_yellowF == yellowF())
    return;
  QColor c = m_color.toCmyk();
  c.setCmykF(c.cyanF(), c.magentaF(), new_yellowF, c.blackF(), c.alphaF());
  set_color(c);
}

void ColorAssistant::set_blackF(qreal new_blackF) {
  if (new_blackF == blackF())
    return;
  QColor c = m_color.toCmyk();
  c.setCmykF(c.cyanF(), c.magentaF(), c.yellowF(), new_blackF, c.alphaF());
  set_color(c);
}

void ColorAssistant::set_cyan(int new_cyan) {
  if (new_cyan == cyan())
    return;
  QColor c = m_color.toCmyk();
  c.setCmyk(new_cyan, c.magenta(), c.yellow(), c.black(), c.alpha());
  set_color(c);
}

void ColorAssistant::set_magenta(int new_magenta) {
  if (new_magenta == magenta())
    return;
  QColor c = m_color.toCmyk();
  c.setCmyk(c.cyan(), new_magenta, c.yellow(), c.black(), c.alpha());
  set_color(c);
}

void ColorAssistant::set_yellow(int new_yellow) {
  if (new_yellow == yellow())
    return;
  QColor c = m_color.toCmyk();
  c.setCmyk(c.cyan(), c.magenta(), new_yellow, c.black(), c.alpha());
  set_color(c);
}

void ColorAssistant::set_black(int new_black) {
  if (new_black == black())
    return;
  QColor c = m_color.toCmyk();
  c.setCmyk(c.cyan(), c.magenta(), c.yellow(), new_black, c.alpha());
  set_color(c);
}

void ColorAssistant::set_hsvHueF(qreal new_hsvHueF) {
  if (new_hsvHueF == hsvHueF())
    return;
  QColor c = m_color.toHsv();
  c.setHsvF(new_hsvHueF, c.hsvSaturationF(), c.valueF(), c.alphaF());
  set_color(c);
}

void ColorAssistant::set_hsvSaturationF(qreal new_hsvSaturationF) {
  if (new_hsvSaturationF == hsvSaturationF())
    return;
  QColor c = m_color.toHsv();
  c.setHsvF(c.hsvHueF(), new_hsvSaturationF, c.valueF(), c.alphaF());
  set_color(c);
}

void ColorAssistant::set_hsvValueF(qreal new_hsvValueF) {
  if (new_hsvValueF == hsvValueF())
    return;
  QColor c = m_color.toHsv();
  c.setHsvF(c.hsvHueF(), c.hsvSaturationF(), new_hsvValueF, c.alphaF());
  set_color(c);
}

void ColorAssistant::set_hsvHue(int new_hsvHue) {
  if (new_hsvHue == hsvHue())
    return;
  QColor c = m_color.toHsv();
  c.setHsv(new_hsvHue, c.hsvSaturation(), c.value(), c.alpha());
  set_color(c);
}

void ColorAssistant::set_hsvSaturation(int new_hsvSaturation) {
  if (new_hsvSaturation == hsvSaturation())
    return;
  QColor c = m_color.toHsv();
  c.setHsv(c.hsvHue(), new_hsvSaturation, c.value(), c.alpha());
  set_color(c);
}

void ColorAssistant::set_hsvValue(int new_hsvValue) {
  if (new_hsvValue == hsvValue())
    return;
  QColor c = m_color.toHsv();
  c.setHsv(c.hsvHue(), c.hsvSaturation(), new_hsvValue, c.alpha());
  set_color(c);
}

void ColorAssistant::set_hslHueF(qreal new_hslHueF) {
  if (new_hslHueF == hslHueF())
    return;
  QColor c = m_color.toHsl();
  c.setHslF(new_hslHueF, c.hslSaturationF(), c.lightnessF(), c.alphaF());
  set_color(c);
}

void ColorAssistant::set_hslSaturationF(qreal new_hslSaturationF) {
  if (new_hslSaturationF == hslSaturationF())
    return;
  QColor c = m_color.toHsl();
  c.setHslF(c.hslHueF(), new_hslSaturationF, c.lightnessF(), c.alphaF());
  set_color(c);
}

void ColorAssistant::set_hslLightnessF(qreal new_hslLightnessF) {
  if (new_hslLightnessF == hslLightnessF())
    return;
  QColor c = m_color.toHsl();
  c.setHslF(c.hslHueF(), c.hslSaturationF(), new_hslLightnessF, c.alphaF());
  set_color(c);
}

void ColorAssistant::set_hslHue(int new_hslHue) {
  if (new_hslHue == hslHue())
    return;
  QColor c = m_color.toHsl();
  c.setHsl(new_hslHue, c.hslSaturation(), c.lightness(), c.alpha());
  set_color(c);
}

void ColorAssistant::set_hslSaturation(int new_hslSaturation) {
  if (new_hslSaturation == hslSaturation())
    return;
  QColor c = m_color.toHsl();
  c.setHsl(c.hslHue(), new_hslSaturation, c.lightness(), c.alpha());
  set_color(c);
}

void ColorAssistant::set_hslLightness(int new_hslLightness) {
  if (new_hslLightness == hslLightness())
    return;
  QColor c = m_color.toHsl();
  c.setHsl(c.hslHue(), c.hslSaturation(), new_hslLightness, c.alpha());
  set_color(c);
}

// ---- 分量 update（相等守卫 + emit）与 getter ----

#define XX_PROP_IMPL(_T_, _N_)                                              \
  void ColorAssistant::update_##_N_(const _T_& x) {                         \
    if (m_##_N_ == x)                                                       \
      return;                                                               \
    m_##_N_ = x;                                                            \
    emit _N_##Changed();                                                    \
  }                                                                         \
  _T_ ColorAssistant::_N_() const {                                         \
    return m_##_N_;                                                         \
  }

XX_PROP_IMPL(qreal, redF)
XX_PROP_IMPL(qreal, greenF)
XX_PROP_IMPL(qreal, blueF)
XX_PROP_IMPL(qreal, alphaF)
XX_PROP_IMPL(int, red)
XX_PROP_IMPL(int, green)
XX_PROP_IMPL(int, blue)
XX_PROP_IMPL(int, alpha)

XX_PROP_IMPL(qreal, cyanF)
XX_PROP_IMPL(qreal, magentaF)
XX_PROP_IMPL(qreal, yellowF)
XX_PROP_IMPL(qreal, blackF)
XX_PROP_IMPL(int, cyan)
XX_PROP_IMPL(int, magenta)
XX_PROP_IMPL(int, yellow)
XX_PROP_IMPL(int, black)

XX_PROP_IMPL(qreal, hsvHueF)
XX_PROP_IMPL(qreal, hsvSaturationF)
XX_PROP_IMPL(qreal, hsvValueF)
XX_PROP_IMPL(int, hsvHue)
XX_PROP_IMPL(int, hsvSaturation)
XX_PROP_IMPL(int, hsvValue)

XX_PROP_IMPL(qreal, hslHueF)
XX_PROP_IMPL(qreal, hslSaturationF)
XX_PROP_IMPL(qreal, hslLightnessF)
XX_PROP_IMPL(int, hslHue)
XX_PROP_IMPL(int, hslSaturation)
XX_PROP_IMPL(int, hslLightness)

#undef XX_PROP_IMPL

QOOL_NS_END
