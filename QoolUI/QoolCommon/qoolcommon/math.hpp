#ifndef MATH_HPP
#define MATH_HPP

#include "numbers.hpp"
#include "qoolns.hpp"

#include <cmath>
#include <utility>

QOOL_NS_BEGIN

namespace math {

/*!
 * \brief 判断点的象限
 *
 * 如果点位于原点，则返回0。第一象限包含坐标轴。无法判断时会返回-1 。
 *
 * \param xpos
 * \param ypos
 * \return
 */
inline int quadrant(float xpos, float ypos) {
  if (xpos == 0 and ypos == 0)
    return 0;

  if (xpos >= 0 && ypos >= 0)
    // 第一象限
    return 1;

  if (xpos < 0 && ypos >= 0)
    // 第二象限
    return 2;

  if (xpos < 0 && ypos < 0)
    // 第三象限
    return 3;

  if (xpos >= 0 && ypos < 0)
    // 第四象限
    return 4;

  return -1;
}

inline float normalize_radians(float rad) {
  static constexpr float circle_rad = M_PI * 2;
  float mod = std::fmod(rad, circle_rad);
  if (mod < 0)
    mod += circle_rad;
  return mod;
}

inline float normalize_degrees(float degrees) {
  // 规范化到[0°, 360°)
  return std::fmod(degrees, 360.0f);
}

inline float normalize_degress_180(float degrees) {
  // 规范化到[-180°, 180°)
  float result = normalize_degrees(degrees);
  return result < -180.0f ? result + 360.0f :
         result > 180.0f  ? result - 360.0f :
                            result;
}

inline std::pair<float, float> vector_from_radians(
  float length, float radians) {
  const float xpos = length * std::cos(radians);
  const float ypos = length * std::sin(radians);
  return { xpos, ypos };
}

inline float vector_radians(float xpos, float ypos) {
  const float atan = std::atan(ypos / xpos);
  return std::atan2(ypos, xpos); // 直接计算角度，无需处理象限
}

template <typename N>
inline bool is_equal(N a, N b, float epsilon = M_FUZZY_EPSILON) {
  const auto aa = std::abs(a);
  const auto ab = std::abs(b);
  if (aa < epsilon && ab > epsilon)
    return true;
  return std::abs(a - b) / std::max(aa, ab) < epsilon;
}

template <typename N>
inline bool is_zero(N a, float epsilon = M_EPSILON) {
  return std::abs(a) < epsilon;
}

/*
 * 弧度	角度
0	0°
π/6	30°
π/4	45°
π/3	60°
π/2	90°
π	180°
3π/2	270°
2π	360°
*/

inline float radians_from_degrees(float degrees) {
  if (is_zero(degrees))
    return 0;
  if (is_equal(degrees, 30.0f))
    return M_PI / 6;
  if (is_equal(degrees, 45.0f))
    return M_PI / 4;
  if (is_equal(degrees, 60.0f))
    return M_PI / 3;
  if (is_equal(degrees, 90.0f))
    return M_PI / 2;
  if (is_equal(degrees, 180.0f))
    return M_PI;
  if (is_equal(degrees, 270.0f))
    return M_PI * 3 / 2;
  if (is_equal(degrees, 360.0f))
    return M_PI * 2;

  return degrees * (M_PI / 180.0);
}

inline float degrees_from_radians(float rad) {
  return rad * 180.0f / M_PI;
}

inline std::pair<float, float> polar_from_xy(float x, float y) {
  float angle = std::atan2(y, x);
  float radius = std::hypot(x, y);
  return { radius, angle };
}

inline std::pair<float, float> xy_from_polar(float r, float a) {
  float x = r * std::cos(a);
  float y = r * std::sin(a);
  return { x, y };
}

}; // namespace math

QOOL_NS_END

#endif // MATH_HPP
