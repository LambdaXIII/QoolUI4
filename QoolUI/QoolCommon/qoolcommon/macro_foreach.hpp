#ifndef MACRO_EXPANDER_HPP
#define MACRO_EXPANDER_HPP

// QOOL_FOREACH_N：同型属性清单批量生成（N 上限版本，行为确定）。
// 用法：对每个元素展开 _M(a)——配合局部宏 __HANDLE__ 使用，用完 #undef。
// 与 macro_foreach_x.hpp（QOOL_MACRO_FOREACH 变参版）区别：本体系 N 显式
// 上限（2..10），无递归展开，行为确定；变参版已弃用（不可用/未完成）。
// 详细文档见 qoolcommon/property_macros.qdoc。
// SIMPLE_FOREACH_MACROS
#define QOOL_FOREACH_2(_M, a, b) _M(a) _M(b)

#define QOOL_FOREACH_3(_M, a, b, c) _M(a) _M(b) _M(c)

#define QOOL_FOREACH_4(_M, a, b, c, d)                                 \
  QOOL_FOREACH_2(_M, a, b) QOOL_FOREACH_2(_M, c, d)

#define QOOL_FOREACH_5(_M, a, b, c, d, e) _M(a) _M(b) _M(c) _M(d) _M(e)

#define QOOL_FOREACH_6(_M, a, b, c, d, e, f)                           \
  QOOL_FOREACH_3(_M, a, b, c) QOOL_FOREACH_3(_M, d, e, f)

#define QOOL_FOREACH_7(_M, _1, _2, _3, _4, _5, _6, _7)                 \
  QOOL_FOREACH_3(_M, _1, _2, _3)                                       \
  QOOL_FOREACH_2(_M, _4, _5) QOOL_FOREACH_2(_M, _6, _7)

#define QOOL_FOREACH_8(_M, _1, _2, _3, _4, _5, _6, _7, _8)             \
  QOOL_FOREACH_3(_M, _1, _2, _3)                                       \
  QOOL_FOREACH_3(_M, _4, _5, _6) QOOL_FOREACH_2(_M, _7, _8)

#define QOOL_FOREACH_9(_M, _1, _2, _3, _4, _5, _6, _7, _8, _9)         \
  QOOL_FOREACH_3(_M, _1, _2, _3)                                       \
  QOOL_FOREACH_3(_M, _4, _5, _6) QOOL_FOREACH_3(_M, _7, _8, _9)

#define QOOL_FOREACH_10(_M, _1, _2, _3, _4, _5, _6, _7, _8, _9, _10)   \
  QOOL_FOREACH_5(_M, _1, _2, _3, _4, _5)                               \
  QOOL_FOREACH_5(_M, _6, _7, _8, _9, _10)

#endif // MACRO_EXPANDER_HPP
