# QML 测试单元：tst_style_qml
# 独立子目录 + 独立 CMakeLists（directory 唯一化）——
# 一个 directory 一个 QML target，Qt Creator QuickTest 解析
# internalTargets(proFile) 命中唯一 target，不再弹 EXECUTABLE 选择。
qoolui_add_qml_test(tst_style_qml tst_style Qool)
