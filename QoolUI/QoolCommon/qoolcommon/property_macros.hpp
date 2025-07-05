#ifndef PROPERTY_MACROS_HPP
#define PROPERTY_MACROS_HPP

#include "_property_helpers.hpp"

#define QOOL_PROPERTY_CONSTANT(_T_, _N_, _D_)                          \
public:                                                                \
  _QL_PROPERTY_GETTER_SIGNATURE_(_T_, _N_) {                           \
    return _QL_MEMBER_NAME_(_N_);                                      \
  }                                                                    \
_QL_PRIVATE_SCOPE_:                                                    \
  _T_ _QL_MEMBER_NAME_(_N_) { _D_ };                                   \
  Q_PROPERTY(_T_ _N_ READ _N_ CONSTANT)

#define QOOL_PROPERTY_CONSTANT_DECL(_T_, _N_)                          \
public:                                                                \
  _QL_PROPERTY_GETTER_SIGNATURE_(_T_, _N_);                            \
_QL_PRIVATE_SCOPE_:                                                    \
  Q_PROPERTY(_T_ _N_ READ _N_ CONSTANT)

#endif // PROPERTY_MACROS_HPP
