if(NOT DEFINED QOOLUI_QML_PROJECT_SETUP_LOADED)
    set(QOOLUI_QML_PROJECT_SETUP_LOADED true)
    message("QOOLUI_QML_PROJECT_SETUP LOADED")
endif()


function(append_qml_dir _V_)
  set(QML_DIRS ${QML_IMPORT_PATH})
  list(APPEND QML_DIRS ${_V_})
  list(REMOVE_DUPLICATES QML_DIRS)
  set(QML_IMPORT_PATH ${QML_DIRS} CACHE STRING "qt qml folder" FORCE)
endfunction()


macro(load_qoolui_standard_options)
    if(NOT DEFINED QOOLUI_STANDARD_OPTIONS_LOADED)
        set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR})
        set(QT_QML_OUTPUT_DIRECTORY ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/qml)
        set(QOOLUI_PLUGIN_OUTPUT_DIRECTORY ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/qoolplugins)
        set(QOOLUI_STANDARD_OPTIONS_LOADED true)
        append_qml_dir(${QT_QML_OUTPUT_DIRECTORY})
        message("QOOLUI STANDARD PROJECT OPTIONS LOADED")
    endif()
endmacro()


macro(copy_qml_modules_for _T_)
  add_custom_command(TARGET ${_T_} POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy_directory ${QT_QML_OUTPUT_DIRECTORY} "$<TARGET_FILE_DIR:${_T_}>/qml"
    COMMAND ${CMAKE_COMMAND} -E copy_directory ${QOOLUI_PLUGIN_OUTPUT_DIRECTORY} "$<TARGET_FILE_DIR:${_T_}>/qoolplugins")
endmacro()
