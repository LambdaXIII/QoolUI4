#include "qool_random_hsv_color_generator.h"

#include <QRandomGenerator>

QOOL_NS_BEGIN

RandomHSVColorGenerator::RandomHSVColorGenerator(QObject* parent)
  : QObject { parent }
  , m_mutex { new QRecursiveMutex } {
}

RandomHSVColorGenerator::~RandomHSVColorGenerator() {
  delete m_mutex;
}

QColor RandomHSVColorGenerator::generate() const {
  QMutexLocker locker(m_mutex);

  QColor result = m_previous;

  while (m_blackList.contains(result) || ! check_previous(result)) {
    if (m_whiteList.isEmpty()) {
      result = QColor::fromHsv(
        randomHue(), randomSat(), randomVal(), randomAlf());
    } else {
      const int index = QRandomGenerator::global()->bounded(
        0, m_whiteList.length() - 1);
      result = m_whiteList.value(index);
    }
  } // while

  return result;
}

int RandomHSVColorGenerator::combinationsCount() const {
  const int hue_count =
    m_preferredHue >= 0 ? 1 : std::abs(_maxHue() - _minHue());
  const int sat_count = m_preferredSaturation >= 0 ?
                          1 :
                          std::abs(_maxSaturation() - _minSaturation());
  const int value_count =
    m_preferredValue >= 0 ? 1 : std::abs(_maxValue() - _minValue());
  const int alpha_count =
    m_preferredAlpha >= 0 ? 1 : std::abs(_maxAlpha() - _minAlpha());
  return hue_count * sat_count * value_count * alpha_count;
}

bool RandomHSVColorGenerator::check_previous(
  const QColor& color) const {
  if (color == m_previous)
    return false;
  QMutexLocker locker(m_mutex);
  m_previous = color;
  return true;
}

int __generate(int min, int max, int preferred, int previous = 0) {
  if (preferred >= 0)
    return preferred;
  const int left = std::min(min, max);
  const int right = std::max(min, max);
  int x = previous;
  while (std::abs(x - previous) < 20)
    x = QRandomGenerator::global()->bounded(left, right);
  return x;
}

int RandomHSVColorGenerator::randomHue() const {
  const int prev = m_previous.hsvHue();
  return __generate(_minHue(), _maxHue(), _preferredHue(), prev);
}

int RandomHSVColorGenerator::randomSat() const {
  const int prev = m_previous.hsvSaturation();
  return __generate(
    _minSaturation(), _maxSaturation(), _preferredSaturation(), prev);
}

int RandomHSVColorGenerator::randomVal() const {
  const int prev = m_previous.value();
  return __generate(_minValue(), _maxValue(), _preferredValue(), prev);
}

int RandomHSVColorGenerator::randomAlf() const {
  const int prev = m_previous.alpha();
  return __generate(_minAlpha(), _maxAlpha(), _preferredAlpha(), prev);
}

QOOL_NS_END
