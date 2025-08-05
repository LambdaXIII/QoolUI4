#ifndef COMPARE_DELEGATE_HPP
#define COMPARE_DELEGATE_HPP

#define QOOL_EQUAL_COMPARE_DECL(CLASS)         \
  bool operator==(const CLASS&, const CLASS&); \
  bool operator!=(const CLASS&, const CLASS&);

#define QOOL_EQUAL_COMPARE_IMPL(CLASS, COMPARE_FUNCTION) \
  bool operator==(const CLASS& lhs, const CLASS& rhs) {  \
    return COMPARE_FUNCTION(lhs, rhs) == 0;              \
  }                                                      \
  bool operator!=(const CLASS& lhs, const CLASS& rhs) {  \
    return COMPARE_FUNCTION(lhs, rhs) != 0;              \
  }

#define QOOL_NUMBERIC_COMPARE_DECL(CLASS)      \
  bool operator<(const CLASS&, const CLASS&);  \
  bool operator>(const CLASS&, const CLASS&);  \
  bool operator<=(const CLASS&, const CLASS&); \
  bool operator>=(const CLASS&, const CLASS&);

#define QOOL_NUMBERIC_COMPARE_IMPL(CLASS, COMPARE_FUNCTION) \
  bool operator<(const CLASS& lhs, const CLASS& rhs) {      \
    return COMPARE_FUNCTION(lhs, rhs) < 0;                  \
  }                                                         \
  bool operator>(const CLASS& lhs, const CLASS& rhs) {      \
    return COMPARE_FUNCTION(lhs, rhs) > 0;                  \
  }                                                         \
  bool operator<=(const CLASS& lhs, const CLASS& rhs) {     \
    return COMPARE_FUNCTION(lhs, rhs) <= 0;                 \
  }                                                         \
  bool operator>=(const CLASS& lhs, const CLASS& rhs) {     \
    return COMPARE_FUNCTION(lhs, rhs) >= 0;                 \
  }

#define QOOL_EQUAL_COMPARE_MEMBER_DECL(CLASS) \
  bool operator==(const CLASS&) const;        \
  bool operator!=(const CLASS&) const;

#define QOOL_EQUAL_COMPARE_MEMBER_IMPL(CLASS, COMPARE_FUNCTION) \
  bool CLASS::operator==(const CLASS& other) const {            \
    return COMPARE_FUNCTION(*this, other) == 0;                 \
  }                                                             \
  bool CLASS::operator!=(const CLASS& other) const {            \
    return COMPARE_FUNCTION(*this, other) != 0;                 \
  }

#define QOOL_NUMBERIC_COMPARE_MEMBER_DECL(CLASS) \
  bool operator<(const CLASS&) const;            \
  bool operator>(const CLASS&) const;            \
  bool operator<=(const CLASS&) const;           \
  bool operator>=(const CLASS&) const;

#define QOOL_NUMBERIC_COMPARE_MEMBER_IMPL(CLASS, COMPARE_FUNCTION) \
  bool CLASS::operator<(const CLASS& other) const {                \
    return COMPARE_FUNCTION(*this, other) < 0;                     \
  }                                                                \
  bool CLASS::operator>(const CLASS& other) const {                \
    return COMPARE_FUNCTION(*this, other) > 0;                     \
  }                                                                \
  bool CLASS::operator<=(const CLASS& other) const {               \
    return COMPARE_FUNCTION(*this, other) <= 0;                    \
  }                                                                \
  bool CLASS::operator>=(const CLASS& other) const {               \
    return COMPARE_FUNCTION(*this, other) >= 0;                    \
  }

#endif // COMPARE_DELEGATE_HPP
