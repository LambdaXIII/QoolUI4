#include "qool_colorassistant.h"

#include "qoolcommon/debug.hpp"

#include <cmath>

QOOL_NS_BEGIN

// 锚 → int 轨换算（QColor 量程：hue 0-359、sat/value/lightness 0-255）；
// normalizeHue 正模归一化 [0,1)、clamp01 钳制 [0,1]。锚恒 ∈[0,1)，
// int 轨随锚换算——灰轴不再产生 -1。
static inline int intFromUnit360(qreal x) { return qRound(x * 360.0) % 360; }
static inline int intFromUnit255(qreal x) { return qRound(x * 255.0); }
static inline qreal normalizeHue(qreal x) {
  return std::fmod(std::fmod(x, 1.0) + 1.0, 1.0);
}
static inline qreal clamp01(qreal x) { return qBound<qreal>(0.0, x, 1.0); }

// 落锚后重建：候选色与当前色相等时 set_color 早退（灰上写 hue、黑上写
// sat 等无表达写——锚已更新而颜色不变），int 轨仍需按新锚刷新。
#define XX_ANCHOR_REBUILD(_CANDIDATE_)                                        \
  do {                                                                        \
    if (m_color != (_CANDIDATE_)) {                                           \
      set_color(_CANDIDATE_);                                                 \
    } else {                                                                  \
      update_hsvHue(intFromUnit360(m_hsvHueF));                               \
      update_hsvSaturation(intFromUnit255(m_hsvSaturationF));                 \
      update_hsvValue(intFromUnit255(m_hsvValueF));                           \
      update_hslHue(intFromUnit360(m_hslHueF));                               \
      update_hslSaturation(intFromUnit255(m_hslSaturationF));                 \
      update_hslLightness(intFromUnit255(m_hslLightnessF));                   \
    }                                                                         \
  } while (0)

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

  // 锚更新三分支（ADR-0020）：value/lightness 恒有表达无条件跟随；hue
  // 派生 ≥0 才覆盖双 hue 锚（灰轴冻结）；hsvSat 仅 v>0、hslSat 仅
  // 0<l<1 时有表达；int 轨一律从锚换算——灰轴不再产生 -1。
  c = c.toHsv();
  update_hsvValueF(c.valueF());
  update_hsvValue(c.value());
  if (c.hsvHueF() >= 0) {
    update_hsvHueF(c.hsvHueF());
    update_hslHueF(c.hsvHueF());
  }
  if (c.valueF() > 0)
    update_hsvSaturationF(c.hsvSaturationF());
  update_hsvHue(intFromUnit360(m_hsvHueF));
  update_hsvSaturation(intFromUnit255(m_hsvSaturationF));

  c = c.toHsl();
  update_hslLightnessF(c.lightnessF());
  update_hslLightness(c.lightness());
  if (c.lightnessF() > 0 && c.lightnessF() < 1)
    update_hslSaturationF(c.hslSaturationF());
  update_hslHue(intFromUnit360(m_hslHueF));
  update_hslSaturation(intFromUnit255(m_hslSaturationF));

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
  const qreal h = normalizeHue(xs.value(0, m_hsvHueF));
  const qreal s = clamp01(xs.value(1, m_hsvSaturationF));
  const qreal v = clamp01(xs.value(2, m_hsvValueF));
  if (!std::isfinite(h) || !std::isfinite(s) || !std::isfinite(v))
    return;
  // 预计算终值（与 set_color 派生同口径：有表达跟随真实换算、无表达落锚），
  // 单次广播后重建为同值 no-op——避免「落锚 emit + 派生覆盖 emit」双发。
  const QColor candidate = QColor::fromHsvF(h, s, v, m_alphaF);
  const QColor ch = candidate.toRgb().toHsv();
  const qreal finalHue = ch.hsvHueF() >= 0 ? ch.hsvHueF() : h;
  const qreal finalSat = ch.valueF() > 0 ? ch.hsvSaturationF() : s;
  const qreal finalValue = ch.valueF();
  update_hsvHueF(finalHue);
  update_hslHueF(finalHue);
  update_hsvSaturationF(finalSat);
  update_hsvValueF(finalValue);
  XX_ANCHOR_REBUILD(candidate);
}

QList<qreal> ColorAssistant::hslF() const {
  return { hslHueF(), hslSaturationF(), hslLightnessF() };
}

void ColorAssistant::set_hslF(QList<qreal> xs) {
  if (xs == hslF())
    return;
  const qreal h = normalizeHue(xs.value(0, m_hslHueF));
  const qreal s = clamp01(xs.value(1, m_hslSaturationF));
  const qreal l = clamp01(xs.value(2, m_hslLightnessF));
  if (!std::isfinite(h) || !std::isfinite(s) || !std::isfinite(l))
    return;
  const QColor candidate = QColor::fromHslF(h, s, l, m_alphaF);
  const QColor ch = candidate.toRgb().toHsl();
  const qreal dh = candidate.toRgb().toHsv().hsvHueF();
  const qreal finalHue = dh >= 0 ? dh : h;
  const qreal finalSat =
      (ch.lightnessF() > 0 && ch.lightnessF() < 1) ? ch.hslSaturationF() : s;
  const qreal finalLight = ch.lightnessF();
  update_hsvHueF(finalHue);
  update_hslHueF(finalHue);
  update_hslSaturationF(finalSat);
  update_hslLightnessF(finalLight);
  XX_ANCHOR_REBUILD(candidate);
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
  const qreal h = normalizeHue(xs.value(0, m_hsvHue) / 360.0);
  const qreal s = clamp01(xs.value(1, m_hsvSaturation) / 255.0);
  const qreal v = clamp01(xs.value(2, m_hsvValue) / 255.0);
  const QColor candidate = QColor::fromHsvF(h, s, v, m_alphaF);
  const QColor ch = candidate.toRgb().toHsv();
  const qreal finalHue = ch.hsvHueF() >= 0 ? ch.hsvHueF() : h;
  const qreal finalSat = ch.valueF() > 0 ? ch.hsvSaturationF() : s;
  const qreal finalValue = ch.valueF();
  update_hsvHueF(finalHue);
  update_hslHueF(finalHue);
  update_hsvSaturationF(finalSat);
  update_hsvValueF(finalValue);
  XX_ANCHOR_REBUILD(candidate);
}

QList<int> ColorAssistant::hsl() const {
  return { hslHue(), hslSaturation(), hslLightness() };
}

void ColorAssistant::set_hsl(QList<int> xs) {
  if (xs == hsl())
    return;
  const qreal h = normalizeHue(xs.value(0, m_hslHue) / 360.0);
  const qreal s = clamp01(xs.value(1, m_hslSaturation) / 255.0);
  const qreal l = clamp01(xs.value(2, m_hslLightness) / 255.0);
  const QColor candidate = QColor::fromHslF(h, s, l, m_alphaF);
  const QColor ch = candidate.toRgb().toHsl();
  const qreal dh = candidate.toRgb().toHsv().hsvHueF();
  const qreal finalHue = dh >= 0 ? dh : h;
  const qreal finalSat =
      (ch.lightnessF() > 0 && ch.lightnessF() < 1) ? ch.hslSaturationF() : s;
  const qreal finalLight = ch.lightnessF();
  update_hsvHueF(finalHue);
  update_hslHueF(finalHue);
  update_hslSaturationF(finalSat);
  update_hslLightnessF(finalLight);
  XX_ANCHOR_REBUILD(candidate);
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
  if (!std::isfinite(new_hsvHueF))
    return;
  const qreal v = normalizeHue(new_hsvHueF);
  if (v == hsvHueF())
    return;
  const QColor candidate = QColor::fromHsvF(v, m_hsvSaturationF, m_hsvValueF,
                                            m_alphaF);
  const qreal derived = candidate.toRgb().toHsv().hsvHueF();
  const qreal final = derived >= 0 ? derived : v;  // 有表达跟随 / 无表达落锚
  update_hsvHueF(final);
  update_hslHueF(final);
  XX_ANCHOR_REBUILD(candidate);
}

void ColorAssistant::set_hsvSaturationF(qreal new_hsvSaturationF) {
  if (!std::isfinite(new_hsvSaturationF))
    return;
  const qreal v = clamp01(new_hsvSaturationF);
  if (v == hsvSaturationF())
    return;
  const QColor candidate = QColor::fromHsvF(m_hsvHueF, v, m_hsvValueF,
                                            m_alphaF);
  const QColor ch = candidate.toRgb().toHsv();
  const qreal final = ch.valueF() > 0 ? ch.hsvSaturationF() : v;  // 黑轴冻结
  update_hsvSaturationF(final);
  XX_ANCHOR_REBUILD(candidate);
}

void ColorAssistant::set_hsvValueF(qreal new_hsvValueF) {
  if (!std::isfinite(new_hsvValueF))
    return;
  const qreal v = clamp01(new_hsvValueF);
  if (v == hsvValueF())
    return;
  const QColor candidate = QColor::fromHsvF(m_hsvHueF, m_hsvSaturationF, v,
                                            m_alphaF);
  const qreal final = candidate.toRgb().toHsv().valueF();  // 恒有表达
  update_hsvValueF(final);
  XX_ANCHOR_REBUILD(candidate);
}

void ColorAssistant::set_hsvHue(int new_hsvHue) {
  if (new_hsvHue == hsvHue())
    return;
  const qreal v = normalizeHue(new_hsvHue / 360.0);
  const QColor candidate = QColor::fromHsvF(v, m_hsvSaturationF, m_hsvValueF,
                                            m_alphaF);
  const qreal derived = candidate.toRgb().toHsv().hsvHueF();
  const qreal final = derived >= 0 ? derived : v;
  update_hsvHueF(final);
  update_hslHueF(final);
  XX_ANCHOR_REBUILD(candidate);
}

void ColorAssistant::set_hsvSaturation(int new_hsvSaturation) {
  if (new_hsvSaturation == hsvSaturation())
    return;
  const qreal v = clamp01(new_hsvSaturation / 255.0);
  const QColor candidate = QColor::fromHsvF(m_hsvHueF, v, m_hsvValueF,
                                            m_alphaF);
  const QColor ch = candidate.toRgb().toHsv();
  const qreal final = ch.valueF() > 0 ? ch.hsvSaturationF() : v;
  update_hsvSaturationF(final);
  XX_ANCHOR_REBUILD(candidate);
}

void ColorAssistant::set_hsvValue(int new_hsvValue) {
  if (new_hsvValue == hsvValue())
    return;
  const qreal v = clamp01(new_hsvValue / 255.0);
  const QColor candidate = QColor::fromHsvF(m_hsvHueF, m_hsvSaturationF, v,
                                            m_alphaF);
  const qreal final = candidate.toRgb().toHsv().valueF();
  update_hsvValueF(final);
  XX_ANCHOR_REBUILD(candidate);
}

void ColorAssistant::set_hslHueF(qreal new_hslHueF) {
  if (!std::isfinite(new_hslHueF))
    return;
  const qreal v = normalizeHue(new_hslHueF);
  if (v == hsvHueF())
    return;
  const QColor candidate = QColor::fromHslF(v, m_hslSaturationF,
                                            m_hslLightnessF, m_alphaF);
  const qreal derived = candidate.toRgb().toHsv().hsvHueF();
  const qreal final = derived >= 0 ? derived : v;
  update_hsvHueF(final);
  update_hslHueF(final);
  XX_ANCHOR_REBUILD(candidate);
}

void ColorAssistant::set_hslSaturationF(qreal new_hslSaturationF) {
  if (!std::isfinite(new_hslSaturationF))
    return;
  const qreal v = clamp01(new_hslSaturationF);
  if (v == hslSaturationF())
    return;
  const QColor candidate = QColor::fromHslF(m_hslHueF, v, m_hslLightnessF,
                                            m_alphaF);
  const QColor ch = candidate.toRgb().toHsl();
  const qreal final = (ch.lightnessF() > 0 && ch.lightnessF() < 1)
      ? ch.hslSaturationF() : v;  // 黑白轴冻结
  update_hslSaturationF(final);
  XX_ANCHOR_REBUILD(candidate);
}

void ColorAssistant::set_hslLightnessF(qreal new_hslLightnessF) {
  if (!std::isfinite(new_hslLightnessF))
    return;
  const qreal v = clamp01(new_hslLightnessF);
  if (v == hslLightnessF())
    return;
  const QColor candidate = QColor::fromHslF(m_hslHueF, m_hslSaturationF, v,
                                            m_alphaF);
  const qreal final = candidate.toRgb().toHsl().lightnessF();  // 恒有表达
  update_hslLightnessF(final);
  XX_ANCHOR_REBUILD(candidate);
}

void ColorAssistant::set_hslHue(int new_hslHue) {
  if (new_hslHue == hslHue())
    return;
  const qreal v = normalizeHue(new_hslHue / 360.0);
  const QColor candidate = QColor::fromHslF(v, m_hslSaturationF,
                                            m_hslLightnessF, m_alphaF);
  const qreal derived = candidate.toRgb().toHsv().hsvHueF();
  const qreal final = derived >= 0 ? derived : v;
  update_hsvHueF(final);
  update_hslHueF(final);
  XX_ANCHOR_REBUILD(candidate);
}

void ColorAssistant::set_hslSaturation(int new_hslSaturation) {
  if (new_hslSaturation == hslSaturation())
    return;
  const qreal v = clamp01(new_hslSaturation / 255.0);
  const QColor candidate = QColor::fromHslF(m_hslHueF, v, m_hslLightnessF,
                                            m_alphaF);
  const QColor ch = candidate.toRgb().toHsl();
  const qreal final = (ch.lightnessF() > 0 && ch.lightnessF() < 1)
      ? ch.hslSaturationF() : v;
  update_hslSaturationF(final);
  XX_ANCHOR_REBUILD(candidate);
}

void ColorAssistant::set_hslLightness(int new_hslLightness) {
  if (new_hslLightness == hslLightness())
    return;
  const qreal v = clamp01(new_hslLightness / 255.0);
  const QColor candidate = QColor::fromHslF(m_hslHueF, m_hslSaturationF, v,
                                            m_alphaF);
  const qreal final = candidate.toRgb().toHsl().lightnessF();
  update_hslLightnessF(final);
  XX_ANCHOR_REBUILD(candidate);
}

#undef XX_ANCHOR_REBUILD

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
