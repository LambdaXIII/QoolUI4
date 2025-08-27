#ifndef QOOLCOMMON_QBINDABLE_PROPERTY_MACROS_HPP
#define QOOLCOMMON_QBINDABLE_PROPERTY_MACROS_HPP

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
