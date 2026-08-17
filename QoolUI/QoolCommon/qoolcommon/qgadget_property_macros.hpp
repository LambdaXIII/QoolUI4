#ifndef QOOLCOMMON_QGADGET_PROPERTY_MACROS_HPP
#define QOOLCOMMON_QGADGET_PROPERTY_MACROS_HPP

// Q_GADGET 值类型属性宏族：无 QObject 特性（无 NOTIFY 信号、无 bindable），
// getter + setter + 成员 + Q_PROPERTY 注册。setter 无相等守卫（值类型
// 通常整值替换）——需要守卫的场景手写。绑定场景（QML 对值类型属性
// 的绑定）依赖 QML 引擎轮询/值重设语义，区别于 QObject 属性。
// 签名：QGADGET_*_PROPERTY(_T_, _N_, _D_, ...)——_D_ 默认值必填；
// ... 为 Q_PROPERTY 附加选项通道。DECLARE 版不生成成员与实现。
// 详细文档见 docs/reference/QoolCommon/property-macros.md。
#include "_property_helpers.hpp"

#define QGADGET_WRITABLE_PROPERTY(_T_, _N_, _D_, ...)                        \
public:                                                                      \
  _QL_PROPERTY_GETTER_SIGNATURE_(_T_, _N_) { return _QL_MEMBER_NAME_(_N_); } \
  _QL_PROPERTY_SETTER_SIGNATURE_(_T_, _N_) {                                 \
    _QL_MEMBER_NAME_(_N_) = _QL_NEW_VALUE_(_N_);                             \
  }                                                                          \
_QL_PRIVATE_SCOPE_:                                                          \
  _T_ _QL_MEMBER_NAME_(_N_){_D_};                                            \
  Q_PROPERTY(_T_ _N_ READ _N_ WRITE set_##_N_ __VA_ARGS__)

#define QGADGET_READONLY_PROPERTY(_T_, _N_, _D_, ...)                        \
public:                                                                      \
  _QL_PROPERTY_GETTER_SIGNATURE_(_T_, _N_) { return _QL_MEMBER_NAME_(_N_); } \
_QL_PRIVATE_SCOPE_:                                                          \
  _T_ _QL_MEMBER_NAME_(_N_){_D_};                                            \
  Q_PROPERTY(_T_ _N_ READ _N_ __VA_ARGS__)

#define QGADGET_CONSTANT_PROPERTY(_T_, _N_, _D_, ...)                        \
public:                                                                      \
  _QL_PROPERTY_GETTER_SIGNATURE_(_T_, _N_) { return _QL_MEMBER_NAME_(_N_); } \
_QL_PRIVATE_SCOPE_:                                                          \
  _T_ _QL_MEMBER_NAME_(_N_){_D_};                                            \
  Q_PROPERTY(_T_ _N_ READ _N_ CONSTANT __VA_ARGS__)

/****** DECLARE ONLY VERSIONS ******/

#define QGADGET_WRITABLE_PROPERTY_DECLARE(_T_, _N_, ...)   \
public:                                                    \
  _QL_PROPERTY_GETTER_SIGNATURE_(_T_, _N_);                \
  _QL_PROPERTY_SETTER_SIGNATURE_(_T_, _N_);                \
_QL_PRIVATE_SCOPE_:                                        \
  Q_PROPERTY(_T_ _N_ READ _N_ WRITE set_##_N_ __VA_ARGS__)

#define QGADGET_READONLY_PROPERTY_DECLARE(_T_, _N_, ...) \
public:                                                  \
  _QL_PROPERTY_GETTER_SIGNATURE_(_T_, _N_);              \
_QL_PRIVATE_SCOPE_:                                      \
  Q_PROPERTY(_T_ _N_ READ _N_ __VA_ARGS__)

#define QGADGET_CONSTANT_PROPERTY_DECLARE(_T_, _N_, ...) \
public:                                                  \
  _QL_PROPERTY_GETTER_SIGNATURE_(_T_, _N_);              \
_QL_PRIVATE_SCOPE_:                                      \
  Q_PROPERTY(_T_ _N_ READ _N_ CONSTANT __VA_ARGS__)

#endif // QOOLCOMMON_QGADGET_PROPERTY_MACROS_HPP
