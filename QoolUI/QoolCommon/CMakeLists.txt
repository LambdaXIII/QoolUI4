add_library(QoolCommon INTERFACE
    qoolcommon/qool_common.h
    qoolcommon/qool_bindable_property.hpp
    qoolcommon/number_utils.hpp
    qoolcommon/_property_helper_macros.hpp
    qoolcommon/qool_property.hpp
)


target_include_directories(QoolCommon
    INTERFACE ${CMAKE_CURRENT_SOURCE_DIR})
