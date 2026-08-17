#ifndef QOOLCOMMON_QBINDABLE_PROPERTY_MACROS_HPP
#define QOOLCOMMON_QBINDABLE_PROPERTY_MACROS_HPP

// QObject bindable 属性宏族：成员为 Q_OBJECT_BINDABLE_PROPERTY（值变化
// 通知走 bindable 而非 setter 显式 emit；相等守卫由 operator= 内置，setter
// 不写守卫是刻意的），并生成 bindable_xxx()（QBindable{&member} 形态，
// Q_PROPERTY 带 BINDABLE 供 QML 引擎走 bindable 接口）。
// 签名：QBINDABLE_*_PROPERTY(_C_, _T_, _N_, ...)——**无默认值参数**；
// ... 为 Q_PROPERTY 附加选项通道（误传默认值会静默进入 Q_PROPERTY 尾部
// 导致 moc Parse error）。DECLARE 版不生成成员，实现归类/类外手写。
// QOOL_MAKE_PROPERTY_BINDABLE：给非宏体系的普通 Q_PROPERTY 补 bindable
// 访问（QBindable{this, name} 形态，用于绑定表达式读取，不用于实现
// BINDABLE——依赖追踪限制见 Qt 文档）。
// 详细文档见 docs/reference/QoolCommon/property-macros.md。
#include "_property_helpers.hpp"

#include <QBindable>

#define _QL_BINDABLE_MEMBER_(_C_, _T_, _N_)                \
  Q_OBJECT_BINDABLE_PROPERTY(                              \
      _C_, _T_, _QL_MEMBER_NAME_(_N_), &_C_::_N_##Changed)

#define _QL_BINDABLE_MEMBER_ARGS_(_C_, _T_, _N_, _D_)           \
  Q_OBJECT_BINDABLE_PROPERTY_WITH_ARGS(                         \
      _C_, _T_, _QL_MEMBER_NAME_(_N_), _D_, &_C_::_N_##Changed)

#define QOOL_BINDABLE_MEMBER(_C_, _T_, _N_) \
  Q_SIGNAL void _N_##Changed();             \
  _QL_BINDABLE_MEMBER_(_C_, _T_, _N_)

#define _QL_STANDARD_BINDABLE_GETTER_(_T_, _N_) \
  QBindable<_T_> _QL_BINDABLE_NAME_(_N_)() { return {&_QL_MEMBER_NAME_(_N_)}; }

#define QOOL_MAKE_PROPERTY_BINDABLE(_T_, _N_) \
  QBindable<_T_> _QL_BINDABLE_NAME_(_N_)() {  \
    return QBindable<_T_>(this, #_N_);        \
  }

#define QBINDABLE_WRITABLE_PROPERTY(_C_, _T_, _N_, ...)                    \
public:                                                                    \
  Q_SIGNAL void _N_##Changed();                                            \
  _QL_PROPERTY_GETTER_SIGNATURE_(_T_, _N_) {                               \
    return _QL_MEMBER_NAME_(_N_).value();                                  \
  }                                                                        \
  _QL_PROPERTY_SETTER_SIGNATURE_(_T_, _N_) {                               \
    _QL_MEMBER_NAME_(_N_) = _QL_NEW_VALUE_(_N_);                           \
  }                                                                        \
  _QL_STANDARD_BINDABLE_GETTER_(_T_, _N_)                                  \
_QL_PRIVATE_SCOPE_:                                                        \
  _QL_BINDABLE_MEMBER_(_C_, _T_, _N_)                                      \
  Q_PROPERTY(_T_ _N_ READ _N_ WRITE set_##_N_ NOTIFY _N_##Changed BINDABLE \
          _QL_BINDABLE_NAME_(_N_) __VA_ARGS__)

#define QBINDABLE_READONLY_PROPERTY(_C_, _T_, _N_, ...)                        \
public:                                                                        \
  Q_SIGNAL void _N_##Changed();                                                \
  _QL_PROPERTY_GETTER_SIGNATURE_(_T_, _N_) {                                   \
    return _QL_MEMBER_NAME_(_N_).value();                                      \
  }                                                                            \
  _QL_STANDARD_BINDABLE_GETTER_(_T_, _N_)                                      \
_QL_PRIVATE_SCOPE_:                                                            \
  _QL_BINDABLE_MEMBER_(_C_, _T_, _N_)                                          \
  Q_PROPERTY(_T_ _N_ READ _N_ NOTIFY _N_##Changed BINDABLE _QL_BINDABLE_NAME_( \
      _N_) __VA_ARGS__)

#define QBINDABLE_SET_VALUE(_N_, _V_) _QL_MEMBER_NAME_(_N_).setValue(_V_);

#define QBINDABLE_SET_BINDING(_N_, _V_) _QL_MEMBER_NAME_(_N_).setBinding(_V_);

#define QBINDABLE_WRITABLE_PROPERTY_DECLARE(_C_, _T_, _N_, ...)            \
public:                                                                    \
  Q_SIGNAL void _N_##Changed();                                            \
  _QL_PROPERTY_GETTER_SIGNATURE_(_T_, _N_);                                \
  _QL_PROPERTY_SETTER_SIGNATURE_(_T_, _N_);                                \
  _QL_STANDARD_BINDABLE_GETTER_(_T_, _N_)                                  \
_QL_PRIVATE_SCOPE_:                                                        \
  _QL_BINDABLE_MEMBER_(_C_, _T_, _N_)                                      \
  Q_PROPERTY(_T_ _N_ READ _N_ WRITE set_##_N_ NOTIFY _N_##Changed BINDABLE \
          _QL_BINDABLE_NAME_(_N_) __VA_ARGS__)

#define QBINDABLE_READONLY_PROPERTY_DECLARE(_C_, _T_, _N_, ...)                \
public:                                                                        \
  Q_SIGNAL void _N_##Changed();                                                \
  _QL_PROPERTY_GETTER_SIGNATURE_(_T_, _N_);                                    \
  _QL_STANDARD_BINDABLE_GETTER_(_T_, _N_)                                      \
_QL_PRIVATE_SCOPE_:                                                            \
  _QL_BINDABLE_MEMBER_(_C_, _T_, _N_)                                          \
  Q_PROPERTY(_T_ _N_ READ _N_ NOTIFY _N_##Changed BINDABLE _QL_BINDABLE_NAME_( \
      _N_) __VA_ARGS__)

#endif // QOOLCOMMON_QBINDABLE_PROPERTY_MACROS_HPP
