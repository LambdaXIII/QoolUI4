#ifndef QOOL_BINDABLE_PROPERTY_HPP
#define QOOL_BINDABLE_PROPERTY_HPP

#include "_property_helper_macros.hpp"

#define QOOL_BINDABLE_PROPERTY(_C_, _T_, _N_)                          \
public:                                                                \
  Q_SIGNAL void _N_##Changed();                                        \
  _T_ _N_() const {                                                    \
    return _Q_MEMBER_NAME_(_N_).value();                               \
  }                                                                    \
  void set_##_N_(_T_ _Q_NEW_VALUE_(_N_)) {                             \
    m_##_N_ = _Q_NEW_VALUE_(_N_);                                      \
  }                                                                    \
  QBindable<_T_> _Q_BINDABLE_NAME_(_N_)() {                            \
    return &_Q_MEMBER_NAME_(_N_);                                      \
  }                                                                    \
                                                                       \
protected:                                                             \
  Q_OBJECT_BINDABLE_PROPERTY(                                          \
    _C_, _T_, _Q_MEMBER_NAME_(_N_), &_C_::_N_##Changed)                \
  Q_PROPERTY(_T_ _N_ READ _N_ WRITE set_##_N_ NOTIFY                   \
      _N_##Changed BINDABLE _Q_BINDABLE_NAME_(_N_))

#define QOOL_DECL_BINDABLE_PROPERTY(_C_, _T_, _N_)                     \
public:                                                                \
  Q_SIGNAL void _N_##Changed();                                        \
  _T_ _N_() const;                                                     \
  void set_##_N_(_T_ _Q_NEW_VALUE_(_N_));                              \
  QBindable<_T_> _Q_BINDABLE_NAME_(_N_)() {                            \
    return &_Q_MEMBER_NAME_(_N_);                                      \
  }                                                                    \
                                                                       \
protected:                                                             \
  Q_OBJECT_BINDABLE_PROPERTY(                                          \
    _C_, _T_, _Q_MEMBER_NAME_(_N_), &_C_::_N_##Changed)                \
  Q_PROPERTY(_T_ _N_ READ _N_ WRITE set_##_N_ NOTIFY                   \
      _N_##Changed BINDABLE _Q_BINDABLE_NAME_(_N_))

#define QOOL_BINDABLE_PROPERTY_READONLY(_C_, _T_, _N_)                 \
public:                                                                \
  Q_SIGNAL void _N_##Changed();                                        \
  _T_ _N_() const {                                                    \
    return _Q_MEMBER_NAME_(_N_).value();                               \
  }                                                                    \
                                                                       \
  QBindable<_T_> _Q_BINDABLE_NAME_(_N_)() {                            \
    return &_Q_MEMBER_NAME_(_N_);                                      \
  }                                                                    \
                                                                       \
protected:                                                             \
  Q_OBJECT_BINDABLE_PROPERTY(                                          \
    _C_, _T_, _Q_MEMBER_NAME_(_N_), &_C_::_N_##Changed)                \
  Q_PROPERTY(                                                          \
    _T_ _N_ READ _N_ NOTIFY _N_##Changed BINDABLE _Q_BINDABLE_NAME_(   \
      _N_))

#define QOOL_BINDABLE_PROPERTY_INIT_VALUE(_N_, _V_)                    \
  _Q_MEMBER_NAME_(_N_).setValue(_V_);
#define QOOL_BINDABLE_PROPERTY_INIT_BINDING(_N_, _V_)                  \
  _Q_MEMBER_NAME_(_N_).setBinding(_V_);

#endif // QOOL_BINDABLE_PROPERTY_HPP
