# QoolCommon 纯 C++ 模板库测试（Qt Test）
# 被测面：qoolcommon/math/*（纯函数/纯模板，QCoreApplication 环境即可）

qoolui_add_cpp_test(
  tst_qoolcommon_math
  tst_math.cpp
)

target_link_libraries(tst_qoolcommon_math PRIVATE QoolCommon)
