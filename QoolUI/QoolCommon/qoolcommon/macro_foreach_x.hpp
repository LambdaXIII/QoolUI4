#ifndef MACRO_FOREACH_X_HPP
#define MACRO_FOREACH_X_HPP

// 计算参数数量（最多支持64个参数）

#define _QL_COUNT_ARGS_IMPL(_1, _2, _3, _4, _5, _6, _7, _8, _9, _10,   \
  _11, _12, _13, _14, _15, _16, _17, _18, _19, _20, _21, _22, _23,     \
  _24, _25, _26, _27, _28, _29, _30, _31, _32, _33, _34, _35, _36,     \
  _37, _38, _39, _40, _41, _42, _43, _44, _45, _46, _47, _48, _49,     \
  _50, _51, _52, _53, _54, _55, _56, _57, _58, _59, _60, _61, _62,     \
  _63, _64, N, ...)                                                    \
  N

#define QOOL_COUNT_ARGS(...)                                           \
  _QL_COUNT_ARGS_IMPL(__VA_ARGS__, 63, 62, 61, 60, 59, 58, 57, 56, 55, \
    54, 53, 52, 51, 50, 49, 48, 47, 46, 45, 44, 43, 42, 41, 40, 39,    \
    38, 37, 36, 35, 34, 33, 32, 31, 30, 29, 28, 27, 26, 25, 24, 23,    \
    22, 21, 20, 19, 18, 17, 16, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, \
    4, 3, 2, 1, 0)

#define _QL_EXPAND_NEXT_63(_M, a, ...)                                 \
  _M(a) _QL_EXPAND_NEXT_62(_M, __VA_ARGS__)

#define _QL_EXPAND_NEXT_62(_M, a, ...)                                 \
  _M(a) _QL_EXPAND_NEXT_61(_M, __VA_ARGS__)

#define _QL_EXPAND_NEXT_61(_M, a, ...)                                 \
  _M(a) _QL_EXPAND_NEXT_60(_M, __VA_ARGS__)

#define _QL_EXPAND_NEXT_60(_M, a, ...)                                 \
  _M(a) _QL_EXPAND_NEXT_59(_M, __VA_ARGS__)

#define _QL_EXPAND_NEXT_59(_M, a, ...)                                 \
  _M(a) _QL_EXPAND_NEXT_58(_M, __VA_ARGS__)

#define _QL_EXPAND_NEXT_58(_M, a, ...)                                 \
  _M(a) _QL_EXPAND_NEXT_57(_M, __VA_ARGS__)

#define _QL_EXPAND_NEXT_57(_M, a, ...)                                 \
  _M(a) _QL_EXPAND_NEXT_56(_M, __VA_ARGS__)

#define _QL_EXPAND_NEXT_56(_M, a, ...)                                 \
  _M(a) _QL_EXPAND_NEXT_55(_M, __VA_ARGS__)

#define _QL_EXPAND_NEXT_55(_M, a, ...)                                 \
  _M(a) _QL_EXPAND_NEXT_54(_M, __VA_ARGS__)

#define _QL_EXPAND_NEXT_54(_M, a, ...)                                 \
  _M(a) _QL_EXPAND_NEXT_53(_M, __VA_ARGS__)

#define _QL_EXPAND_NEXT_53(_M, a, ...)                                 \
  _M(a) _QL_EXPAND_NEXT_52(_M, __VA_ARGS__)

#define _QL_EXPAND_NEXT_52(_M, a, ...)                                 \
  _M(a) _QL_EXPAND_NEXT_51(_M, __VA_ARGS__)

#define _QL_EXPAND_NEXT_51(_M, a, ...)                                 \
  _M(a) _QL_EXPAND_NEXT_50(_M, __VA_ARGS__)

#define _QL_EXPAND_NEXT_50(_M, a, ...)                                 \
  _M(a) _QL_EXPAND_NEXT_49(_M, __VA_ARGS__)

#define _QL_EXPAND_NEXT_49(_M, a, ...)                                 \
  _M(a) _QL_EXPAND_NEXT_48(_M, __VA_ARGS__)

#define _QL_EXPAND_NEXT_48(_M, a, ...)                                 \
  _M(a) _QL_EXPAND_NEXT_47(_M, __VA_ARGS__)

#define _QL_EXPAND_NEXT_47(_M, a, ...)                                 \
  _M(a) _QL_EXPAND_NEXT_46(_M, __VA_ARGS__)

#define _QL_EXPAND_NEXT_46(_M, a, ...)                                 \
  _M(a) _QL_EXPAND_NEXT_45(_M, __VA_ARGS__)

#define _QL_EXPAND_NEXT_45(_M, a, ...)                                 \
  _M(a) _QL_EXPAND_NEXT_44(_M, __VA_ARGS__)

#define _QL_EXPAND_NEXT_44(_M, a, ...)                                 \
  _M(a) _QL_EXPAND_NEXT_43(_M, __VA_ARGS__)

#define _QL_EXPAND_NEXT_43(_M, a, ...)                                 \
  _M(a) _QL_EXPAND_NEXT_42(_M, __VA_ARGS__)

#define _QL_EXPAND_NEXT_42(_M, a, ...)                                 \
  _M(a) _QL_EXPAND_NEXT_41(_M, __VA_ARGS__)

#define _QL_EXPAND_NEXT_41(_M, a, ...)                                 \
  _M(a) _QL_EXPAND_NEXT_40(_M, __VA_ARGS__)

#define _QL_EXPAND_NEXT_40(_M, a, ...)                                 \
  _M(a) _QL_EXPAND_NEXT_39(_M, __VA_ARGS__)

#define _QL_EXPAND_NEXT_39(_M, a, ...)                                 \
  _M(a) _QL_EXPAND_NEXT_38(_M, __VA_ARGS__)

#define _QL_EXPAND_NEXT_38(_M, a, ...)                                 \
  _M(a) _QL_EXPAND_NEXT_37(_M, __VA_ARGS__)

#define _QL_EXPAND_NEXT_37(_M, a, ...)                                 \
  _M(a) _QL_EXPAND_NEXT_36(_M, __VA_ARGS__)

#define _QL_EXPAND_NEXT_36(_M, a, ...)                                 \
  _M(a) _QL_EXPAND_NEXT_35(_M, __VA_ARGS__)

#define _QL_EXPAND_NEXT_35(_M, a, ...)                                 \
  _M(a) _QL_EXPAND_NEXT_34(_M, __VA_ARGS__)

#define _QL_EXPAND_NEXT_34(_M, a, ...)                                 \
  _M(a) _QL_EXPAND_NEXT_33(_M, __VA_ARGS__)

#define _QL_EXPAND_NEXT_33(_M, a, ...)                                 \
  _M(a) _QL_EXPAND_NEXT_32(_M, __VA_ARGS__)

#define _QL_EXPAND_NEXT_32(_M, a, ...)                                 \
  _M(a) _QL_EXPAND_NEXT_31(_M, __VA_ARGS__)

#define _QL_EXPAND_NEXT_31(_M, a, ...)                                 \
  _M(a) _QL_EXPAND_NEXT_30(_M, __VA_ARGS__)

#define _QL_EXPAND_NEXT_30(_M, a, ...)                                 \
  _M(a) _QL_EXPAND_NEXT_29(_M, __VA_ARGS__)

#define _QL_EXPAND_NEXT_29(_M, a, ...)                                 \
  _M(a) _QL_EXPAND_NEXT_28(_M, __VA_ARGS__)

#define _QL_EXPAND_NEXT_28(_M, a, ...)                                 \
  _M(a) _QL_EXPAND_NEXT_27(_M, __VA_ARGS__)

#define _QL_EXPAND_NEXT_27(_M, a, ...)                                 \
  _M(a) _QL_EXPAND_NEXT_26(_M, __VA_ARGS__)

#define _QL_EXPAND_NEXT_26(_M, a, ...)                                 \
  _M(a) _QL_EXPAND_NEXT_25(_M, __VA_ARGS__)

#define _QL_EXPAND_NEXT_25(_M, a, ...)                                 \
  _M(a) _QL_EXPAND_NEXT_24(_M, __VA_ARGS__)

#define _QL_EXPAND_NEXT_24(_M, a, ...)                                 \
  _M(a) _QL_EXPAND_NEXT_23(_M, __VA_ARGS__)

#define _QL_EXPAND_NEXT_23(_M, a, ...)                                 \
  _M(a) _QL_EXPAND_NEXT_22(_M, __VA_ARGS__)

#define _QL_EXPAND_NEXT_22(_M, a, ...)                                 \
  _M(a) _QL_EXPAND_NEXT_21(_M, __VA_ARGS__)

#define _QL_EXPAND_NEXT_21(_M, a, ...)                                 \
  _M(a) _QL_EXPAND_NEXT_20(_M, __VA_ARGS__)

#define _QL_EXPAND_NEXT_20(_M, a, ...)                                 \
  _M(a) _QL_EXPAND_NEXT_19(_M, __VA_ARGS__)

#define _QL_EXPAND_NEXT_19(_M, a, ...)                                 \
  _M(a) _QL_EXPAND_NEXT_18(_M, __VA_ARGS__)

#define _QL_EXPAND_NEXT_18(_M, a, ...)                                 \
  _M(a) _QL_EXPAND_NEXT_17(_M, __VA_ARGS__)

#define _QL_EXPAND_NEXT_17(_M, a, ...)                                 \
  _M(a) _QL_EXPAND_NEXT_16(_M, __VA_ARGS__)

#define _QL_EXPAND_NEXT_16(_M, a, ...)                                 \
  _M(a) _QL_EXPAND_NEXT_15(_M, __VA_ARGS__)

#define _QL_EXPAND_NEXT_15(_M, a, ...)                                 \
  _M(a) _QL_EXPAND_NEXT_14(_M, __VA_ARGS__)

#define _QL_EXPAND_NEXT_14(_M, a, ...)                                 \
  _M(a) _QL_EXPAND_NEXT_13(_M, __VA_ARGS__)

#define _QL_EXPAND_NEXT_13(_M, a, ...)                                 \
  _M(a) _QL_EXPAND_NEXT_12(_M, __VA_ARGS__)

#define _QL_EXPAND_NEXT_12(_M, a, ...)                                 \
  _M(a) _QL_EXPAND_NEXT_11(_M, __VA_ARGS__)

#define _QL_EXPAND_NEXT_11(_M, a, ...)                                 \
  _M(a) _QL_EXPAND_NEXT_10(_M, __VA_ARGS__)

#define _QL_EXPAND_NEXT_10(_M, a, ...)                                 \
  _M(a) _QL_EXPAND_NEXT_9(_M, __VA_ARGS__)

#define _QL_EXPAND_NEXT_9(_M, a, ...)                                  \
  _M(a) _QL_EXPAND_NEXT_8(_M, __VA_ARGS__)

#define _QL_EXPAND_NEXT_8(_M, a, ...)                                  \
  _M(a) _QL_EXPAND_NEXT_7(_M, __VA_ARGS__)

#define _QL_EXPAND_NEXT_7(_M, a, ...)                                  \
  _M(a) _QL_EXPAND_NEXT_6(_M, __VA_ARGS__)

#define _QL_EXPAND_NEXT_6(_M, a, ...)                                  \
  _M(a) _QL_EXPAND_NEXT_5(_M, __VA_ARGS__)

#define _QL_EXPAND_NEXT_5(_M, a, ...)                                  \
  _M(a) _QL_EXPAND_NEXT_4(_M, __VA_ARGS__)

#define _QL_EXPAND_NEXT_4(_M, a, ...)                                  \
  _M(a) _QL_EXPAND_NEXT_3(_M, __VA_ARGS__)

#define _QL_EXPAND_NEXT_3(_M, a, ...)                                  \
  _M(a) _QL_EXPAND_NEXT_2(_M, __VA_ARGS__)

#define _QL_EXPAND_NEXT_2(_M, a, ...)                                  \
  _M(a) _QL_EXPAND_NEXT_1(_M, __VA_ARGS__)

#define _QL_EXPAND_NEXT_1(_M, a, b) _M(a) _M(b)

#define _QL_EXPAND_NEXT_0(_M, a) _M(a)

#define _QL_CONCAT(a, b) __QL_CONCAT(a, b)
#define __QL_CONCAT(a, b) a##b

#define _QL_EXPAND_NEXT(_M, ...)                                       \
  _QL_CONCAT(_QL_EXPAND_NEXT_, QOOL_COUNT_ARGS(__VA_ARGS__))(          \
    _M, __VA_ARGS__)

#define QOOL_MACRO_FOREACH(_M, ...) _QL_EXPAND_NEXT(_M, __VA_ARGS__)

#endif // MACRO_FOREACH_X_HPP
