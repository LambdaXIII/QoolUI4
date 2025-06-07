#ifndef PROPERTY_MACROS_FOR_QOBJECT_DECLONLY_HPP
#define PROPERTY_MACROS_FOR_QOBJECT_DECLONLY_HPP

#include "_property_helpers.hpp"

#define QOOL_PROPERTY_WRITABLE_FOR_QOBJECT_DECL(_T_, _N_)              \
public:                                                                \
  Q_SIGNAL void _N_##Changed();                                        \
  _QL_PROPERTY_GETTER_SIGNATURE_(_T_, _N_);                            \
  _QL_PROPERTY_SETTER_SIGNATURE_(_T_, _N_);                            \
_QL_PRIVATE_SCOPE_:                                                    \
  Q_PROPERTY(_T_ _N_ READ _N_ WRITE set_##_N_ NOTIFY _N_##Changed)

#define QOOL_PROPERTY_READONLY_FOR_QOBJECT_DECL(_T_, _N_, _D_)         \
public:                                                                \
  Q_SIGNAL void _N_##Changed();                                        \
  _QL_PROPERTY_GETTER_SIGNATURE_(_T_, _N_);                            \
  _QL_PROPERTY_SETTER_SIGNATURE_(_T_, _N_);                            \
_QL_PRIVATE_SCOPE_:                                                    \
  Q_PROPERTY(_T_ _N_ READ _N_ NOTIFY _N_##Changed)

#define QOOL_PROPERTY_PRIVATE_FOR_QOBJECT_DECL(_T_, _N_, _D_)          \
public:                                                                \
  Q_SIGNAL void _N_##Changed();                                        \
  _QL_PROPERTY_GETTER_SIGNATURE_(_T_, _N_);                            \
_QL_PRIVATE_SCOPE_:                                                    \
  _QL_PROPERTY_SETTER_SIGNATURE_(_T_, _N_);                            \
  Q_PROPERTY(_T_ _N_ READ _N_ NOTIFY _N_##Changed)

#define QOOL_PROPERTY_CONSTANT_FOR_QOBJECT_DECL(_T_, _N_, _D_)         \
public:                                                                \
  _QL_PROPERTY_GETTER_SIGNATURE_(_T_, _N_);                            \
  _T_ _QL_MEMBER_NAME_(_N_) { _D_ };                                   \
  Q_PROPERTY(_T_ _N_ READ _N_ CONSTANT)

#endif // PROPERTY_MACROS_FOR_QOBJECT_DECLONLY_HPP
