#ifndef PROPERTY_MACROS_FOR_QOBJECT_HPP
#define PROPERTY_MACROS_FOR_QOBJECT_HPP

#include "_property_helpers.hpp"

#define _QL_SETTER_BODY_(_N_)                                          \
  if (_QL_MEMBER_NAME_(_N_) == _QL_NEW_VALUE_(_N_))                    \
    return;                                                            \
  _QL_MEMBER_NAME_(_N_) = _QL_NEW_VALUE_(_N_);

#define QOOL_PROPERTY_WRITABLE_FOR_QOBJECT(_T_, _N_, _D_)              \
public:                                                                \
  Q_SIGNAL void _N_##Changed();                                        \
  _QL_PROPERTY_GETTER_SIGNATURE_(_T_, _N_) {                           \
    return _QL_MEMBER_NAME_(_N_);                                      \
  }                                                                    \
  _QL_PROPERTY_SETTER_SIGNATURE_(_T_, _N_) {                           \
    _QL_SETTER_BODY_(_N_);                                             \
    emit _N_##Changed();                                               \
  }                                                                    \
_QL_PRIVATE_SCOPE_:                                                    \
  _T_ _QL_MEMBER_NAME_(_N_) { _D_ };                                   \
  Q_PROPERTY(_T_ _N_ READ _N_ WRITE set_##_N_ NOTIFY _N_##Changed)

#define QOOL_PROPERTY_READONLY_FOR_QOBJECT(_T_, _N_, _D_)              \
public:                                                                \
  Q_SIGNAL void _N_##Changed();                                        \
  _QL_PROPERTY_GETTER_SIGNATURE_(_T_, _N_) {                           \
    return _QL_MEMBER_NAME_(_N_);                                      \
  }                                                                    \
  _QL_PROPERTY_SETTER_SIGNATURE_(_T_, _N_) {                           \
    _QL_SETTER_BODY_(_N_);                                             \
    emit _N_##Changed();                                               \
  }                                                                    \
_QL_PRIVATE_SCOPE_:                                                    \
  _T_ _QL_MEMBER_NAME_(_N_) { _D_ };                                   \
  Q_PROPERTY(_T_ _N_ READ _N_ NOTIFY _N_##Changed)

#define QOOL_PROPERTY_PRIVATE_FOR_QOBJECT(_T_, _N_, _D_)               \
public:                                                                \
  Q_SIGNAL void _N_##Changed();                                        \
  _QL_PROPERTY_GETTER_SIGNATURE_(_T_, _N_) {                           \
    return _QL_MEMBER_NAME_(_N_);                                      \
  }                                                                    \
_QL_PRIVATE_SCOPE_:                                                    \
  _QL_PROPERTY_SETTER_SIGNATURE_(_T_, _N_) {                           \
    _QL_SETTER_BODY_(_N_);                                             \
    emit _N_##Changed();                                               \
  }                                                                    \
  _T_ _QL_MEMBER_NAME_(_N_) { _D_ };                                   \
  Q_PROPERTY(_T_ _N_ READ _N_ NOTIFY _N_##Changed)

#define QOOL_PROPERTY_CONSTANT_FOR_QOBJECT(_T_, _N_, _D_)              \
public:                                                                \
  _QL_PROPERTY_GETTER_SIGNATURE_(_T_, _N_) {                           \
    return _QL_MEMBER_NAME_(_N_);                                      \
  }                                                                    \
_QL_PRIVATE_SCOPE_:                                                    \
  _T_ _QL_MEMBER_NAME_(_N_) { _D_ };                                   \
  Q_PROPERTY(_T_ _N_ READ _N_ CONSTANT)

#endif // PROPERTY_MACROS_FOR_QOBJECT_HPP
