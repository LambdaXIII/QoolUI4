#ifndef PROPERTY_MACROS_FOR_QOBJECT_HPP
#define PROPERTY_MACROS_FOR_QOBJECT_HPP

// QObject 属性宏族：一条宏 = 信号 + getter + setter + 成员 + Q_PROPERTY。
// 签名：QOBJECT_*_PROPERTY(_T_, _N_, _D_, ...)——_D_ 为默认值（必填，
// 可传 T{}）；... 为 Q_PROPERTY 附加选项通道（CONSTANT/FINAL 等，勿传
// 默认值——会静默进入 Q_PROPERTY 尾部导致 moc Parse error）。
// DECLARE 版(_T_, _N_, ...)不生成成员与实现，仅声明，实现归类/类外手写。
// 详细文档见 docs/reference/QoolCommon/property-macros.md。
#include "_property_helpers.hpp"

#define QOBJECT_WRITABLE_PROPERTY(_T_, _N_, _D_, ...)                          \
public:                                                                        \
  Q_SIGNAL void _N_##Changed();                                                \
  _QL_PROPERTY_GETTER_SIGNATURE_(_T_, _N_) { return _QL_MEMBER_NAME_(_N_); }   \
  _QL_PROPERTY_SETTER_SIGNATURE_(_T_, _N_) {                                   \
    if (_QL_MEMBER_NAME_(_N_) == _QL_NEW_VALUE_(_N_)) return;                  \
    _QL_MEMBER_NAME_(_N_) = _QL_NEW_VALUE_(_N_);                               \
    emit _N_##Changed();                                                       \
  }                                                                            \
_QL_PRIVATE_SCOPE_:                                                            \
  _T_ _QL_MEMBER_NAME_(_N_){_D_};                                              \
  Q_PROPERTY(_T_ _N_ READ _N_ WRITE set_##_N_ NOTIFY _N_##Changed __VA_ARGS__)

#define QOBJECT_READONLY_PROPERTY(_T_, _N_, _D_, ...)                        \
public:                                                                      \
  Q_SIGNAL void _N_##Changed();                                              \
  _QL_PROPERTY_GETTER_SIGNATURE_(_T_, _N_) { return _QL_MEMBER_NAME_(_N_); } \
_QL_PRIVATE_SCOPE_:                                                          \
  _T_ _QL_MEMBER_NAME_(_N_){_D_};                                            \
  Q_PROPERTY(_T_ _N_ READ _N_ NOTIFY _N_##Changed __VA_ARGS__)

#define QOBJECT_CONSTANT_PROPERTY(_T_, _N_, _D_, ...)                        \
public:                                                                      \
  _QL_PROPERTY_GETTER_SIGNATURE_(_T_, _N_) { return _QL_MEMBER_NAME_(_N_); } \
_QL_PRIVATE_SCOPE_:                                                          \
  _T_ _QL_MEMBER_NAME_(_N_){_D_};                                            \
  Q_PROPERTY(_T_ _N_ READ _N_ CONSTANT __VA_ARGS__)

/****** DECLARE ONLY VERSIONS ******/

#define QOBJECT_WRITABLE_PROPERTY_DECLARE(_T_, _N_, ...)                       \
public:                                                                        \
  Q_SIGNAL void _N_##Changed();                                                \
  _QL_PROPERTY_GETTER_SIGNATURE_(_T_, _N_);                                    \
  _QL_PROPERTY_SETTER_SIGNATURE_(_T_, _N_);                                    \
_QL_PRIVATE_SCOPE_:                                                            \
  Q_PROPERTY(_T_ _N_ READ _N_ WRITE set_##_N_ NOTIFY _N_##Changed __VA_ARGS__)

#define QOBJECT_READONLY_PROPERTY_DECLARE(_T_, _N_, ...)       \
public:                                                        \
  Q_SIGNAL void _N_##Changed();                                \
  _QL_PROPERTY_GETTER_SIGNATURE_(_T_, _N_);                    \
_QL_PRIVATE_SCOPE_:                                            \
  Q_PROPERTY(_T_ _N_ READ _N_ NOTIFY _N_##Changed __VA_ARGS__)

#define QOBJECT_CONSTANT_PROPERTY_DECLARE(_T_, _N_, ...) \
public:                                                  \
  _QL_PROPERTY_GETTER_SIGNATURE_(_T_, _N_);              \
_QL_PRIVATE_SCOPE_:                                      \
  Q_PROPERTY(_T_ _N_ READ _N_ CONSTANT __VA_ARGS__)

#endif // PROPERTY_MACROS_FOR_QOBJECT_HPP
