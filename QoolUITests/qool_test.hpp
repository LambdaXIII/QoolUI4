// QoolUI 测试共享头 —— 宏族定义（用法见 QoolUITests/AGENTS.md「测试方法规范」）
//
// 设计约束：
// - 类声明必须显式书写（class X : public QObject { Q_OBJECT ... ），宏不包裹类
//   ——clang-format 无法识别宏内类声明（TESTUNIT 被否决的原因）
// - 禁用 private slots: 区语法入宏（moc 不收集宏内槽区，槽丢失，
//   测试表现为仅 init/cleanup 通过）
// - main 不包装：无 GUI 用 QTEST_APPLESS_MAIN、GUI 用 QTEST_MAIN（原生按需选）
// - moc include 用显式文件名（#include "tst_xxx.moc"）：QT_MOC 宏（Qt 6.1+）
//   在 CMake AUTOMOC 下不可用——CMake 4.4.2 官方文档无 QT_MOC 支持，
//   AUTOMOC 只识别字面 #include "xxx.moc"
// - 不引入自定义 logger：QTest 标准输出足够
#ifndef QOOL_TEST_HPP
#define QOOL_TEST_HPP

// 测试用例宏：展开为 private: Q_SLOT void _N_()
// 类体内使用，函数体内联定义（init/cleanup/xxx_data 同宏）：
//   class TestXxx : public QObject {
//     Q_OBJECT
//     QOOL_TEST_CASE(test_foo) { ... }
//   };
#define QOOL_TEST_CASE(_N_) private: Q_SLOT void _N_()

#endif // QOOL_TEST_HPP
