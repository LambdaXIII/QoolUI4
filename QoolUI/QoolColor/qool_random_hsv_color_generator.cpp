#include "qool_random_hsv_color_generator.h"

#include <QRandomGenerator>

QOOL_NS_BEGIN

// 四通道语义（preferred 锁定 / 区间随机）、255 量化与色相满环映射、
// 防重复与黑白名单规则见 docs/reference/Qool.Color/RandomHSVColorGenerator.md。
// 255 量化（步 360/256 ≈ 1.41°）是刻意设计：与「色相与上次差 ≥ 20」的
// 防重复约束配套，勿改更细粒度或改浮点构造。

namespace {
// 255 量化域 → 0..359 色相角（整数路径；qRound 四舍五入，% 360 处理
// 255 → 360° ≡ 0° 的环状回绕）。
inline int hue_degrees(int hue255) {
  return qRound(qreal(hue255) * 360.0 / 255.0) % 360;
}
} // namespace

RandomHSVColorGenerator::RandomHSVColorGenerator(QObject* parent)
  : QObject { parent }
  , m_mutex { new QRecursiveMutex } {
}

RandomHSVColorGenerator::~RandomHSVColorGenerator() {
  delete m_mutex;
}

QColor RandomHSVColorGenerator::generate() {
  QMutexLocker locker(m_mutex);

  QColor result = m_previous;

  while (m_blackList.contains(result) || ! check_previous(result)) {
    if (m_whiteList.isEmpty()) {
      // 色相 255 量化域 → 0..359 度整数路径（禁止 fromHsvF）：直接喂
      // 量化域，输入 1.0 只覆盖 70.8% 色相环。
      result = QColor::fromHsv(
        hue_degrees(randomHue()), randomSat(), randomVal(), randomAlf());
    } else {
      const int index = QRandomGenerator::global()->bounded(
        0, m_whiteList.length() - 1);
      result = m_whiteList.value(index);
    }
  } // while

  return result;
}

int RandomHSVColorGenerator::count() const {
  // count() 公式（勿改）：锁定通道计 0、乘积 + 1（默认配置 alpha 锁定
  // → 返回 1）。属性名 count 为公开 QML API。
  const int hue_count =
    m_preferredHue >= 0 ? 0 : std::abs(_maxHue() - _minHue());
  const int sat_count = m_preferredSaturation >= 0 ?
                          0 :
                          std::abs(_maxSaturation() - _minSaturation());
  const int value_count =
    m_preferredValue >= 0 ? 0 : std::abs(_maxValue() - _minValue());
  const int alpha_count =
    m_preferredAlpha >= 0 ? 0 : std::abs(_maxAlpha() - _minAlpha());
  return hue_count * sat_count * value_count * alpha_count + 1;
}

bool RandomHSVColorGenerator::check_previous(const QColor& color) {
  if (color == m_previous)
    return false;
  QMutexLocker locker(m_mutex);
  m_previous = color;
  Q_EMIT previousChanged();
  return true;
}

int RandomHSVColorGenerator::randomHue() const {
  if (m_preferredHue >= 0)
    return _preferredHue();
  // previous 统一 255 域：hsvHueF()（0..1）→ 量化域。
  // 无彩上一次 hsvHueF() == -1 → prev = -255 → 首次随机即通过
  // （|x + 255| ≥ 255 > 20），即无彩颜色不构成色相约束。
  const int prev = qRound(m_previous.hsvHueF() * 255);
  int x = prev;
  const int left = std::min(_minHue(), _maxHue());
  const int right = std::max(_minHue(), _maxHue());
  while (std::abs(x - prev) < 20)
    x = QRandomGenerator::global()->bounded(left, right);
  return x;
}

// 防重复（差 ≥ 20）仅色相通道；其余通道无约束均匀随机。
int RandomHSVColorGenerator::randomSat() const {
  if (m_preferredSaturation >= 0)
    return _preferredSaturation();
  const int left = std::min(_minSaturation(), _maxSaturation());
  const int right = std::max(_minSaturation(), _maxSaturation());
  return QRandomGenerator::global()->bounded(left, right);
}

int RandomHSVColorGenerator::randomVal() const {
  if (m_preferredValue >= 0)
    return _preferredValue();
  const int left = std::min(_minValue(), _maxValue());
  const int right = std::max(_minValue(), _maxValue());
  return QRandomGenerator::global()->bounded(left, right);
}

int RandomHSVColorGenerator::randomAlf() const {
  if (m_preferredAlpha >= 0)
    return _preferredAlpha();
  const int left = std::min(_minAlpha(), _maxAlpha());
  const int right = std::max(_minAlpha(), _maxAlpha());
  return QRandomGenerator::global()->bounded(left, right);
}

// 属性语义（区间/锁定/默认值/黑白名单）见
// docs/reference/Qool.Color/RandomHSVColorGenerator.md。

QOOL_NS_END
