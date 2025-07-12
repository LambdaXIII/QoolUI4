set_source_files_properties(
  GlobalChatRoom.qml
PROPERTIES
  QT_QML_SINGLETON_TYPE TRUE
)

qt_add_qml_module( QoolChat
  URI Qool.Chat
  VERSION ${QOOLUI_VERSION_QML}
  NAMESPACE ${QOOL_NS}
  IMPORTS Qool
  SOURCES
    qool_chatroom_server.h
    qool_chatroom_server.cpp
  SOURCES
    qool_message_event.h
    qool_message_event.cpp
  SOURCES
    qool_message.h
    qool_message.cpp
    SOURCES qool_msgchannel.h qool_msgchannel.cpp
    SOURCES qool_beeper.h qool_beeper.cpp
    SOURCES qool_chatroom.h qool_chatroom.cpp
    SOURCES qool_chatroom_manager.h qool_chatroom_manager.cpp
    QML_FILES GlobalChatRoom.qml
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
target_link_libraries(
  QoolChat
  PRIVATE Qt6::Core
  PRIVATE QoolCommon
)


target_include_directories(QoolChat PRIVATE ${CMAKE_CURRENT_SOURCE_DIR})
