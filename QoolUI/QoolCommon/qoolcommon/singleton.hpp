#ifndef QOOLCOMMON_SINGLETON_HPP
#define QOOLCOMMON_SINGLETON_HPP

#define QOOL_SIMPLE_SINGLETON_DECL(_CLS_)                              \
private:                                                               \
  static _CLS_* m_instance;                                            \
  _CLS_();                                                             \
                                                                       \
public:                                                                \
  static _CLS_* instance();

#define QOOL_SIMPLE_SINGLETON_STL_IMPL(_CLS_)                          \
  _CLS_* _CLS_::m_instance { nullptr };                                \
  _CLS_* _CLS_::instance() {                                           \
    /* 原 DCL：无锁读 m_instance 与其他线程的写构成数据竞争（UB），   */ \
    /* 且 lock_guard 传 &mutex（指针）无法编译。改用函数内 static    */ \
    /* （C++11 magic statics）——初始化线程安全、零锁开销；           */ \
    /* m_instance 仅保留定义以匹配 DECL 声明，不再作为实例源。       */ \
    static _CLS_* const singleton = new _CLS_;                         \
    return singleton;                                                  \
  }

#define QOOL_SIMPLE_SINGLETON_QT_IMPL(_CLS_)                           \
  _CLS_* _CLS_::m_instance { nullptr };                                \
  _CLS_* _CLS_::instance() {                                           \
    /* 原 DCL 无锁读 m_instance 存在数据竞争（UB），同 STL_IMPL：     */ \
    /* 函数内 static 初始化线程安全，m_instance 仅保留定义。         */ \
    static _CLS_* const singleton = new _CLS_;                         \
    return singleton;                                                  \
  }

#endif // QOOLCOMMON_SINGLETON_HPP
