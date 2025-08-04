#ifndef COMPARE_DELEGATE_HPP
#define COMPARE_DELEGATE_HPP

#define QOOL_COMPARE_FUNCTION __qool_compare__

#define QOOL_COMPARE_FUNCTION_IMPL(CLASS, LHS, RHS, BODY)            \
  int QOOL_COMPARE_FUNCTION(const CLASS& LHS, const CLASS& RHS) BODY

#define QOOL_EQUAL_COMPARE_DECL(CLASS)         \
  bool operator==(const CLASS&, const CLASS&); \
  bool operator!=(const CLASS&, const CLASS&);

#define QOOL_EQUAL_COMPARE_IMPL(CLASS)                  \
  bool operator==(const CLASS& lhs, const CLASS& rhs) { \
    return QOOL_COMPARE_FUNCTION(lhs, rhs) == 0;        \
  }                                                     \
  bool operator!=(const CLASS& lhs, const CLASS& rhs) { \
    return QOOL_COMPARE_FUNCTION(lhs, rhs) != 0;        \
  }

#define QOOL_NOTEQUAL_COMPARE_DECL(CLASS)      \
  bool operator>(const CLASS&, const CLASS&);  \
  bool operator<(const CLASS&, const CLASS&);  \
  bool operator>=(const CLASS&, const CLASS&); \
  bool operator<=(const CLASS&, const CLASS&);

#define QOOL_NOTEQUAL_COMPARE_IMPL(CLASS)               \
  bool operator>(const CLASS& lhs, const CLASS& rhs) {  \
    return QOOL_COMPARE_FUNCTION(lhs, rhs) > 0;         \
  }                                                     \
  bool operator>=(const CLASS& lhs, const CLASS& rhs) { \
    return QOOL_COMPARE_FUNCTION(lhs, rhs) >= 0;        \
  }                                                     \
  bool operator<(const CLASS& lhs, const CLASS& rhs) {  \
    return QOOL_COMPARE_FUNCTION(lhs, rhs) < 0;         \
  }                                                     \
  bool operator<=(const CLASS& lhs, const CLASS& rhs) { \
    return QOOL_COMPARE_FUNCTION(lhs, rhs) <= 0;        \
  }

#endif // COMPARE_DELEGATE_HPP
