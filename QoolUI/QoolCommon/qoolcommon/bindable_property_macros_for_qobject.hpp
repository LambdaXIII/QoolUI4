#ifndef BINDABLE_PROPERTY_MACROS_FOR_QOBJECT_HPP
#define BINDABLE_PROPERTY_MACROS_FOR_QOBJECT_HPP

#include "_property_helpers.hpp"

#include <QBindable>

#define QOOL_BINDABLE_MEMBER(_C_, _T_, _N_)                            \
  Q_OBJECT_BINDABLE_PROPERTY(                                          \
    _C_, _T_, _QL_MEMBER_NAME_(_N_), &_C_::_N_##Changed)

#define QOOL_BINDABLE_MEMBER_WITH_ARGS(_C_, _T_, _N_, _D_)             \
  Q_OBJECT_BINDABLE_PROPERTY_WITH_ARGS(                                \
    _C_, _T_, _QL_MEMBER_NAME_(_N_), _D_, &_C_::_N_##Changed)

#define _QL_STANDARD_BINDABLE_GETTER_(_T_, _N_)                        \
  QBindable<_T_> _QL_BINDABLE_NAME_(_N_)() {                           \
    return { &_QL_MEMBER_NAME_(_N_) };                                 \
  }

#define QOOL_PROPERTY_WRITABLE_FOR_QOBJECT_BINDABLE(_C_, _T_, _N_)     \
public:                                                                \
  Q_SIGNAL void _N_##Changed();                                        \
  _QL_PROPERTY_GETTER_SIGNATURE_(_T_, _N_) {                           \
    return _QL_MEMBER_NAME_(_N_).value();                              \
  }                                                                    \
  _QL_PROPERTY_SETTER_SIGNATURE_(_T_, _N_) {                           \
    _QL_MEMBER_NAME_(_N_) = _QL_NEW_VALUE_(_N_);                       \
  }                                                                    \
  _QL_STANDARD_BINDABLE_GETTER_(_T_, _N_)                              \
_QL_PRIVATE_SCOPE_:                                                    \
  QOOL_BINDABLE_MEMBER(_C_, _T_, _N_)                                  \
  Q_PROPERTY(_T_ _N_ READ _N_ WRITE set_##_N_ NOTIFY                   \
      _N_##Changed BINDABLE _QL_BINDABLE_NAME_(_N_))

#define QOOL_PROPERTY_PRIVATE_FOR_QOBJECT_BINDABLE(_C_, _T_, _N_)      \
public:                                                                \
  Q_SIGNAL void _N_##Changed();                                        \
  _QL_PROPERTY_GETTER_SIGNATURE_(_T_, _N_) {                           \
    return _QL_MEMBER_NAME_(_N_).value();                              \
  }                                                                    \
  _QL_STANDARD_BINDABLE_GETTER_(_T_, _N_)                              \
_QL_PRIVATE_SCOPE_:                                                    \
  _QL_PROPERTY_SETTER_SIGNATURE_(_T_, _N_) {                           \
    _QL_MEMBER_NAME_(_N_) = _QL_NEW_VALUE_(_N_);                       \
  }                                                                    \
  QOOL_BINDABLE_MEMBER(_C_, _T_, _N_)                                  \
  Q_PROPERTY(                                                          \
    _T_ _N_ READ _N_ NOTIFY _N_##Changed BINDABLE _QL_BINDABLE_NAME_(  \
      _N_))

#define QOOL_PROPERTY_BINDABLE_INIT_VALUE(_N_, _V_)                    \
  _QL_MEMBER_NAME_(_N_).setValue(_V_);

#define QOOL_PROPERTY_BINDABLE_INIT_BINDING(_N_, _V_)                  \
  _QL_MEMBER_NAME_(_N_).setBinding(_V_);

#endif // BINDABLE_PROPERTY_MACROS_FOR_QOBJECT_HPP
