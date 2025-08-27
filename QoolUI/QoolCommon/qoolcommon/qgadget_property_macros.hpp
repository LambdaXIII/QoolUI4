#ifndef QOOLCOMMON_QGADGET_PROPERTY_MACROS_HPP
#define QOOLCOMMON_QGADGET_PROPERTY_MACROS_HPP

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
  _QL_PROPERTY_SETTER_SIGNATURE_(_T_, _N_);              \
_QL_PRIVATE_SCOPE_:                                      \
  Q_PROPERTY(_T_ _N_ READ _N_ __VA_ARGS__)

#define QGADGET_CONSTANT_PROPERTY_DECLARE(_T_, _N_, ...) \
public:                                                  \
  _QL_PROPERTY_GETTER_SIGNATURE_(_T_, _N_);              \
_QL_PRIVATE_SCOPE_:                                      \
  Q_PROPERTY(_T_ _N_ READ _N_ CONSTANT __VA_ARGS__)

#endif // QOOLCOMMON_QGADGET_PROPERTY_MACROS_HPP
