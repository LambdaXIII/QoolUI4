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

// 注意：曾有过 QOOL_SIMPLE_SINGLETON_QML_CREATE（把进程级单例伪装成
// QML 单例）——违反 Qt 契约（共享实例经 QML_SINGLETON 暴露只能被一个
// QQmlEngine 访问），多 engine 崩溃，已删除。需要 QML 暴露的进程级
// 能力走「单例组件设计模式」三件套（XxxDB + XxxHQ + 可选 XxxHQModel），
// 见根 AGENTS.md 已知陷阱（QML 引擎唯一性）。

#endif // QOOLCOMMON_SINGLETON_HPP
