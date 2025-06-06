#ifndef QOOL_PROPERTY_HPP
#define QOOL_PROPERTY_HPP

#include "_property_helper_macros.hpp"

#define QOOL_PROPERTY(_T_, _N_, _D_)                                   \
public:                                                                \
  Q_SIGNAL void _N_##Changed();                                        \
  _T_ _N_() const {                                                    \
    return _Q_MEMBER_NAME_(_N_);                                       \
  }                                                                    \
  void set_##_N_(_T_ _Q_NEW_VALUE_(_N_)) {                             \
    if (_Q_NEW_VALUE_(_N_) == _Q_MEMBER_NAME_(_N_))                    \
      return;                                                          \
    _Q_MEMBER_NAME_(_N_) = _Q_NEW_VALUE_(_N_);                         \
  }                                                                    \
                                                                       \
protected:                                                             \
  _T_ _Q_MEMBER_NAME_(_N_) { _D_ };                                    \
  Q_PROPERTY(_T_ _N_ READ _N_ WRITE set_##_N_ NOTIFY _N_##Changed)

#define QOOL_DECL_PROPERTY(_T_, _N_)                                   \
public:                                                                \
  Q_SIGNAL void _N_##Changed();                                        \
  _T_ _N_() const;                                                     \
  void set_##_N_(_T_ _Q_NEW_VALUE_(_N_));                              \
                                                                       \
protected:                                                             \
  Q_PROPERTY(_T_ _N_ READ _N_ WRITE set_##_N_ NOTIFY _N_##Changed)

#endif // QOOL_PROPERTY_HPP
