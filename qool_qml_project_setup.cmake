if(NOT DEFINED QOOLUI_QML_PROJECT_SETUP_LOADED)
  set(QOOLUI_QML_PROJECT_SETUP_LOADED true)
  message(STATUS "QOOLUI_QML_PROJECT_SETUP LOADED")
endif()


function(append_qml_dir _V_)
  set(QML_DIRS ${QML_IMPORT_PATH})
  list(APPEND QML_DIRS ${_V_})
  list(REMOVE_DUPLICATES QML_DIRS)
  set(QML_IMPORT_PATH ${QML_DIRS} CACHE STRING "qt qml folder" FORCE)
  message("Adding QML_IMPORT_PATH: ${_V_}")
endfunction()

function(dump_list LIST_VAR)
  foreach(item ${${LIST_VAR}})
    message(STATUS "${LIST_VAR}: ${item}")
  endforeach()
endfunction()

macro(load_qoolui_standard_options)
  if(NOT DEFINED QOOLUI_STANDARD_OPTIONS_LOADED)
    set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR})
    set(QOOLUI_PLUGIN_OUTPUT_DIRECTORY ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/qoolplugins)
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
  add_custom_command(TARGET ${_T_} POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy_directory ${QT_QML_OUTPUT_DIRECTORY} "$<TARGET_FILE_DIR:${_T_}>/qml"
    COMMAND ${CMAKE_COMMAND} -E copy_directory ${QOOLUI_PLUGIN_OUTPUT_DIRECTORY} "$<TARGET_FILE_DIR:${_T_}>/qoolplugins")
endmacro()


function(convert_paths_to_relative VAR_NAME BASE_DIR)
  # 获取原始变量的值（绝对路径列表）
  set(ABSOLUTE_PATHS "${${VAR_NAME}}")
  set(RELATIVE_PATHS "")

  foreach(ABS_PATH ${ABSOLUTE_PATHS})
    file(RELATIVE_PATH REL_PATH "${BASE_DIR}" "${ABS_PATH}")
    list(APPEND RELATIVE_PATHS "${REL_PATH}")
  endforeach()

  # 直接修改调用者作用域中的变量
  set(${VAR_NAME} ${RELATIVE_PATHS} PARENT_SCOPE)
endfunction()

function(qoolui_scan_assets_to OUTPUT_VAR)
  set(ASS_DIR "${CMAKE_CURRENT_SOURCE_DIR}/assets")
  if(NOT EXISTS ${ASS_DIR})
    message(WARNING "assets directory not exists.")
    set(${OUTPUT_VAR} "" PARENT_SCOPE})
    return()
  endif()
  file(GLOB_RECURSE ASS_PATHS "${CMAKE_CURRENT_SOURCE_DIR}/assets/*")
  convert_paths_to_relative(ASS_PATHS ${CMAKE_CURRENT_SOURCE_DIR})
  message("qoolui assets found in ${CMAKE_CURRENT_SOURCE_DIR}:")
  foreach(_X_ ${ASS_PATHS})
    message("  ${_X_}")
  endforeach()
  set(${OUTPUT_VAR} ${ASS_PATHS} PARENT_SCOPE)
endfunction()
