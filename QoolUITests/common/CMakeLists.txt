# QoolCommon 纯 C++ 模板库测试（Qt Test）
# 被测面：qoolcommon/math/*（纯函数/纯模板，QCoreApplication 环境即可）
#
# 输出树下沉：本层 exe 输出到 build/build-<kit>-<Type>/QoolUITests/common/，
# DLL 按层共享一份（copy_if_different 幂等）。目录级变量只影响本目录树，
# 不碰主设置（CMAKE_RUNTIME_OUTPUT_DIRECTORY=${CMAKE_BINARY_DIR}）。
#
# 规模化模式：自动发现——新增 tst_*.cpp 零配置自动注册
# （file(GLOB CONFIGURE_DEPENDS)：Ninja 构建时检测新文件并自动重新配置；
#  不支持 CONFIGURE_DEPENDS 的生成器需手动重新配置一次）

set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/QoolUITests/common")

file(GLOB QOOLCOMMON_TEST_SOURCES CONFIGURE_DEPENDS
  "${CMAKE_CURRENT_SOURCE_DIR}/tst_*.cpp"
)

foreach(tst IN LISTS QOOLCOMMON_TEST_SOURCES)
  get_filename_component(tst_name ${tst} NAME_WE)
  qoolui_add_cpp_test(${tst_name} ${tst})
  target_link_libraries(${tst_name} PRIVATE QoolCommon QoolUITestSupport)
endforeach()