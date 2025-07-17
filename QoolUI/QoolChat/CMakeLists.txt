set_source_files_properties(
  GlobalChatRoom.qml PROPERTIES QT_QML_SINGLETON_TYPE TRUE
)

find_package(Qt6 REQUIRED COMPONENTS Core)
find_package(Qt6 REQUIRED COMPONENTS Core)
find_package(Qt6 REQUIRED COMPONENTS Core)

qt_add_qml_module(QoolChat
  URI Qool.Chat
  VERSION ${QOOLUI_VERSION_QML}
  NAMESPACE ${QOOL_NS}
  IMPORTS Qool

  SOURCES

  qool_chatroom_server.h
  qool_chatroom_server.cpp
  qool_message_event.h
  qool_message_event.cpp
  qool_message.h
  qool_message.cpp
  qool_msgchannel.h
  qool_msgchannel.cpp
  qool_msgchannelset.h
  qool_msgchannelset.cpp
  qool_beeper.h
  qool_beeper.cpp
  qool_chatroom.h
  qool_chatroom.cpp
  qool_chatroom_manager.h
  qool_chatroom_manager.cpp

  apps/qool_basicbeeperapp.h
  apps/qool_basicbeeperapp.cpp
  apps/qool_messagelogger.h
  apps/qool_messagelogger.cpp

  QML_FILES

  GlobalChatRoom.qml
)

set_target_properties(
  QoolChat
  PROPERTIES MACOSX_BUNDLE_GUI_IDENTIFIER org.qoolui.chat
             MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
             MACOSX_BUNDLE_SHORT_VERSION_STRING
             ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
             MACOSX_BUNDLE TRUE
             WIN32_EXECUTABLE TRUE
)

target_compile_definitions(
  QoolChat
  PRIVATE $<$<OR:$<CONFIG:Debug>,$<CONFIG:RelWithDebInfo>>:QT_QML_DEBUG>
)
target_link_libraries(QoolChat
  PRIVATE Qt6::Core
  PRIVATE QoolCommon
)

target_include_directories(QoolChat
  PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}
  PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/apps
)
