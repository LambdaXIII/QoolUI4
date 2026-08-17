# math 几何工具（QoolCommon）

## 函数

### `float qoolui::math::normalize_radians(float rad)`

将弧度角 `rad` 规范化到 [0, 2π) 区间（模 2π 折返，非钳制）。

`fmod` 保留被除数符号：负角得到负余数，必须补一个圆周
（`+2π`）归位，保证结果落在 [0, 2π)。

### `float qoolui::math::normalize_degrees(float degrees)`

将角度 `degrees` 规范化到 [0°, 360°) 区间。

与 `normalize_radians` 语义对称：`fmod` 对负角产生负余数，
必须补 360° 归位，保证结果非负。

### `float qoolui::math::normalize_degrees_180(float degrees)`

将角度 `degrees` 规范化到 [-180°, 180°) 区间。

先经 `normalize_degrees` 归入 [0°, 360°)，再对超过 180° 的
结果减 360° 折入负半周。

### `std::pair<float, float> qoolui::math::vector_from_radians(float length, float radians)`

由长度与弧度角构造直角坐标向量。

- 返回：形如 `{x, y}` 的坐标对：
  `x = length*cos(radians)`、`y = length*sin(radians)`。

### `float qoolui::math::radians_from_degrees(float degrees)`

角度转弧度。

常见特殊角（0/30/45/60/90/180/270/360 度，在容差内相等）直接
返回精确常量（如 30° → π/6）；其余按 `degrees * π/180` 换算。

### `float qoolui::math::degrees_from_radians(float rad)`

弧度转角度的线性换算：`rad * 180/π`。

### `std::pair<float, float> qoolui::math::polar_from_xy(float x, float y)`

直角坐标转极坐标。

- 返回：形如 `{radius, angle}` 的极坐标对：半径用 `hypot`
  计算（避免平方和溢出/下溢），角度用 `atan2` 直接判定象限。

### `std::pair<float, float> qoolui::math::xy_from_polar(float r, float a)`

极坐标转直角坐标。

- 返回：形如 `{x, y}` 的坐标对：
  `x = r*cos(a)`、`y = r*sin(a)`。

### `float qoolui::math::hypotenuse(float leg1, float leg2)`

求直角三角形斜边长度：sqrt(leg1² + leg2²)。
