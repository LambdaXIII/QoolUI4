if(NOT DEFINED QOOLUI_QML_PROJECT_SETUP_LOADED)
  set(QOOLUI_QML_PROJECT_SETUP_LOADED true)
  message(STATUS "QOOLUI_QML_PROJECT_SETUP LOADED")
endif()

function(append_qml_dir _V_)
  set(QML_DIRS ${QML_IMPORT_PATH})
  list(APPEND QML_DIRS ${_V_})
  list(REMOVE_DUPLICATES QML_DIRS)
  set(QML_IMPORT_PATH
      ${QML_DIRS}
      CACHE STRING "qt qml folder" FORCE
  )
  message("Adding QML_IMPORT_PATH: ${_V_}")
endfunction()

function(dump_list LIST_VAR)
  foreach(item ${${LIST_VAR}})
    message(STATUS "${LIST_VAR}: ${item}")
  endforeach()
endfunction()

macro(load_qoolui_standard_options)
  if(NOT DEFINED QOOLUI_STANDARD_OPTIONS_LOADED)

    if(NOT DEFINED QOOL_NS)
      set(QOOL_NS "qoolui")
    endif()

    if(NOT DEFINED QOOL_PLUGIN_DIR)
      set(QOOL_PLUGIN_DIR "qoolplugins")
    endif()

    # 构建开关（宿主引入时可整体关闭；默认 ON 本仓库自洽优先）：
    # - QOOL_BUILD_TESTS（构建侧总闸）：测试目录（QoolUITests）是否加入——
    #   关闭时测试树彻底消失（连其 include(CTest) 都不执行）
    # - QOOL_BUILD_EXAMPLEAPP：示例程序（QoolUIExample）是否加入
    # 注册侧标准开关 BUILD_TESTING（include(CTest) 自带，见 QoolUITests）：
    # 只关 BUILD_TESTING = 测试仍构建但 ctest 不注册（run-tests 仍可用）
    if(NOT DEFINED QOOL_BUILD_TESTS)
      set(QOOL_BUILD_TESTS ON CACHE BOOL "Build the test facility (QoolUITests)")
    endif()
    if(NOT DEFINED QOOL_BUILD_EXAMPLEAPP)
      set(QOOL_BUILD_EXAMPLEAPP
          ON
          CACHE BOOL "Build the example application (QoolUIExample)"
      )
    endif()

    set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR})
    set(QOOLUI_PLUGIN_OUTPUT_DIRECTORY
        "${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/${QOOL_PLUGIN_DIR}"
    )
    set(QT_QML_OUTPUT_DIRECTORY ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/qml)
    append_qml_dir(${QT_QML_OUTPUT_DIRECTORY})
    set(QT_QML_GENERATE_QMLLS_INI ON)

    if(QT_KNOWN_POLICY_QTP0001)
      message(STATUS "QTP0001: Enabled")
      qt_policy(SET QTP0001 NEW)
    endif()

    if(QT_KNOWN_POLICY_QTP0004)
      message(STATUS "QTP0004: Enabled")
      qt_policy(SET QTP0004 NEW)
    endif()

    if(QT_KNOWN_POLICY_QTP0005)
      message(STATUS "QTP0005: Enabled")
      qt_policy(SET QTP0005 NEW)
    endif()

    message(STATUS "QOOLUI STANDARD PROJECT OPTIONS LOADED")
    set(QOOLUI_STANDARD_OPTIONS_LOADED true)
  endif()
endmacro()

macro(copy_qml_modules_for _T_)
  add_custom_command(
    TARGET ${_T_}
    POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy_directory ${QT_QML_OUTPUT_DIRECTORY}
            "$<TARGET_FILE_DIR:${_T_}>/qml"
    COMMAND ${CMAKE_COMMAND} -E copy_directory
            ${QOOLUI_PLUGIN_OUTPUT_DIRECTORY}
            "$<TARGET_FILE_DIR:${_T_}>/qoolplugins"
  )
endmacro()

function(qoolui_collect_assets OUTPUT_VAR)
  set(ASS_DIR "${CMAKE_CURRENT_SOURCE_DIR}/assets")
  if(NOT EXISTS ${ASS_DIR})
    message(WARNING "assets directory not exists.")
    set(${OUTPUT_VAR} "" PARENT_SCOPE)
    return()
  endif()
  # RELATIVE 直接产出相对 CMAKE_CURRENT_SOURCE_DIR 的路径，免去二次转换
  file(GLOB_RECURSE ASS_PATHS RELATIVE "${CMAKE_CURRENT_SOURCE_DIR}"
       "${CMAKE_CURRENT_SOURCE_DIR}/assets/*")
  message("qoolui assets found in ${CMAKE_CURRENT_SOURCE_DIR}:")
  foreach(_X_ ${ASS_PATHS})
    message("  ${_X_}")
  endforeach()
  set(${OUTPUT_VAR}
      ${ASS_PATHS}
      PARENT_SCOPE
  )
endfunction()
