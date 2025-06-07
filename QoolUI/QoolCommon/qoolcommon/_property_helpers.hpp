#ifndef _PROPERTY_HELPERS_HPP
#define _PROPERTY_HELPERS_HPP

#include <type_traits>

#define _QL_PRIVATE_SCOPE_ protected
#define _QL_MEMBER_NAME_(_N_) m_##_N_
#define _QL_NEW_VALUE_(_N_) new_##_N_
#define _QL_BINDABLE_NAME_(_N_) bindable_##_N_

#define _QL_PARAM_TYPE_(_T_)                                           \
  typename std::conditional<std::is_pointer<_T_>::value, _T_,          \
    const _T_&>::type

#define _QL_PROPERTY_GETTER_SIGNATURE_(_T_, _N_) _T_ _N_() const
#define _QL_PROPERTY_SETTER_SIGNATURE_(_T_, _N_)                       \
  void set_##_N_(_QL_PARAM_TYPE_(_T_) _QL_NEW_VALUE_(_N_))

#endif // _PROPERTY_HELPERS_HPP
