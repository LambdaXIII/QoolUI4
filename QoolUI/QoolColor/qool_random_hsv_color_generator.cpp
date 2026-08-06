#include "qool_random_hsv_color_generator.h"

#include <QRandomGenerator>

QOOL_NS_BEGIN

/*!
    \qmltype RandomHSVColorGenerator
    \inqmlmodule Qool.Color
    \nativetype qoolui::RandomHSVColorGenerator
    \brief 受约束随机 HSV 颜色生成器：区间随机 + 锁定 + 防重复。

    全部输入为 0..1 归一化 qreal，hue / saturation / value / alpha
    四通道各自独立遵循同一语义；输出恒为整数分量颜色，可规整写为
    #RRGGBB（不透明）或 #AARRGGBB。

    \section2 四通道语义（preferred 锁定 / 随机）

    \list
    \li \c preferredX ≥ 0：该通道\b 锁定为 preferredX，不做随机，
        忽略 minimumX / maximumX；
    \li \c preferredX < 0（默认 -1）：该通道在 [minimumX, maximumX] 内随机
        （min / max 自动取小大为界）。
    \endlist

    默认配置：hue 全环随机（0..1）、saturation 与 value 0.25..1、
    alpha \b 锁定为 1（不透明）——\l preferredAlpha 默认 1 是刻意设计：
    随机取色默认不透明，宿主需要透明才显式放开（< 0 启用随机）。

    \section2 255 量化（刻意设计，请勿当作 bug 修改）

    内部统一按 0..255 整数量化（量化步 360/256 ≈ 1.41°）。量化粒度
    与「与上次生成结果\b 色相差 ≥ 20」的防重复约束配套（其余通道
    无约束均匀随机）。把 255 改成更细粒度、或改用浮点构造，
    都会破坏防重复语义——255 是设计的一部分，不是实现细节。

    \section2 色相满环映射（v3 缺陷修复，整数路径）

    色相在 0..255 量化域内生成，构造颜色时按
    \c qRound(hue * 360 / 255) % 360 满环映射到 0..359 度，喂给
    QColor::fromHsv 的 \e int 重载。\b 禁止改用 fromHsvF 浮点构造。

    v3 缺陷：量化域 0..255 直接喂给 fromHsv（其 h 参数域为 0..359），
    输入 1.0 实际只覆盖 70.8% 色相环；且 previous 比较跨域
    （hsvHue() 返回 0..359 与量化域 0..255 直接相减），语义不准。
    本修复：previous 统一取 255 域（hsvHueF() * 255；无彩时 hsvHueF()
    返回 -1 → 上一次无色相约束，该次随机直接通过），生成时再做满环
    映射。映射结果 255 → 360° ≡ 0°，与 0 同义（环状回绕）。

    \section2 防重复与黑白名单

    \list
    \li 防重复：\b 色相通道与上一次生成结果差 ≥ 20 才接受
        （sat/value/alpha 无此约束，均匀随机）；
    \li \l whiteList 非空时优先从 whiteList 取色（仍受 blackList 与
        防重复约束）；
    \li \l blackList 排除：命中 blackList 的颜色不会被返回。
    \endlist

    \section2 线程安全

    generate() 内部以互斥锁串行化；previous 状态受锁保护，可跨线程
    调用（锁为 QRecursiveMutex，generate 内部对 previous 的检查与
    更新是重入的）。
*/

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
      // 色相 255 量化域 → 0..359 度整数路径（禁止 fromHsvF）：
      // v3 直接喂量化域，输入 1.0 只覆盖 70.8% 色相环。
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
  // 专项注释（缺陷修复）：迁移静默把 v3 count() 改名 combinationsCount() 并
  // 改动公式（锁定通道由计 0 改计 1、去掉 +1）——无裁定依据（spec 仅裁定
  // hue 满环修复），v3 调用方迁移后 ReferenceError。恢复 v3 逐字公式：
  // 锁定通道计 0、乘积 + 1（默认配置 alpha 锁定 → 返回 1）。
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

// 专项注释（v3 行为恢复）：v3 中防重复（差 ≥ 20）仅色相通道；
// 迁移曾过度解读扩大到全通道，按裁定恢复为无约束均匀随机。
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

/*!
    \qmlproperty real Qool.Color::RandomHSVColorGenerator::minimumHue
    \brief 色相下限（0..1 归一化；preferredHue < 0 时随机区间下限）。
    默认 0。
*/

/*!
    \qmlproperty real Qool.Color::RandomHSVColorGenerator::maximumHue
    \brief 色相上限（0..1 归一化；preferredHue < 0 时随机区间上限）。
    默认 1——满环（配合色相满环映射覆盖全部 0..359 度）。
*/

/*!
    \qmlproperty real Qool.Color::RandomHSVColorGenerator::preferredHue
    \brief 锁定色相（0..1 归一化）。≥ 0 时色相通道锁定为 preferredHue
    （忽略 min / max）；< 0（默认 -1）时随机。注意 1.0 与 0.0 同义
    （360° ≡ 0°，满环回绕）。
*/

/*!
    \qmlproperty real Qool.Color::RandomHSVColorGenerator::minimumSaturation
    \brief 饱和度下限（0..1 归一化；preferredSaturation < 0 时随机区间下限）。
    默认 0.25。
*/

/*!
    \qmlproperty real Qool.Color::RandomHSVColorGenerator::maximumSaturation
    \brief 饱和度上限（0..1 归一化；preferredSaturation < 0 时随机区间上限）。
    默认 1。
*/

/*!
    \qmlproperty real Qool.Color::RandomHSVColorGenerator::preferredSaturation
    \brief 锁定饱和度（0..1 归一化）。≥ 0 锁定；< 0（默认 -1）随机。
*/

/*!
    \qmlproperty real Qool.Color::RandomHSVColorGenerator::minimumValue
    \brief 明度下限（0..1 归一化；preferredValue < 0 时随机区间下限）。
    默认 0.25。
*/

/*!
    \qmlproperty real Qool.Color::RandomHSVColorGenerator::maximumValue
    \brief 明度上限（0..1 归一化；preferredValue < 0 时随机区间上限）。
    默认 1。
*/

/*!
    \qmlproperty real Qool.Color::RandomHSVColorGenerator::preferredValue
    \brief 锁定明度（0..1 归一化）。≥ 0 锁定；< 0（默认 -1）随机。
*/

/*!
    \qmlproperty real Qool.Color::RandomHSVColorGenerator::minimumAlpha
    \brief 透明度下限（0..1 归一化；preferredAlpha < 0 时随机区间下限）。
    默认 0。
*/

/*!
    \qmlproperty real Qool.Color::RandomHSVColorGenerator::maximumAlpha
    \brief 透明度上限（0..1 归一化；preferredAlpha < 0 时随机区间上限）。
    默认 1。
*/

/*!
    \qmlproperty real Qool.Color::RandomHSVColorGenerator::preferredAlpha
    \brief 锁定透明度（0..1 归一化）。默认 \b 1（不透明，刻意设计）——
    随机取色默认不透明；< 0 时启用 alpha 随机（区间 [minimumAlpha,
    maximumAlpha]）。
*/

/*!
    \qmlproperty color Qool.Color::RandomHSVColorGenerator::previous
    \brief 上一次成功生成的颜色（只读）。默认 \c Qt::white——首次
    generate() 只需与白色不同。
*/

/*!
    \qmlproperty list<color> Qool.Color::RandomHSVColorGenerator::blackList
    \brief 排除列表：生成结果命中其中任一颜色时重掷（优先级低于
    whiteList——whiteList 命中但同时在 blackList 中仍会被排除）。
    默认空。
*/

/*!
    \qmlproperty list<color> Qool.Color::RandomHSVColorGenerator::whiteList
    \brief 白名单：非空时优先从其中随机取色（跳过 HSV 随机构造；
    仍受 blackList 与防重复约束）。默认空。
*/

/*!
    \qmlmethod color RandomHSVColorGenerator::generate()
    \brief 生成一个满足当前约束的颜色。

    返回值满足：不在 blackList 中、与上一次 generate() 结果不同
    （色相通道差 ≥ 20；sat/value/alpha 无约束随机）、preferred ≥ 0
    的通道恒为锁定值。
    首次调用时 previous 为默认白色，只需与白色不同。
*/

QOOL_NS_END
