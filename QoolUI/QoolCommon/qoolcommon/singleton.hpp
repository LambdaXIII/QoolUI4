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
    static std::mutex mutex;                                           \
    if (m_instance == nullptr) {                                       \
      std::lock_guard<std::mutex> locker(&mutex);                      \
      if (m_instance == nullptr)                                       \
        m_instance = new _CLS_;                                        \
    }                                                                  \
    return m_instance;                                                 \
  }

#define QOOL_SIMPLE_SINGLETON_QT_IMPL(_CLS_)                           \
  _CLS_* _CLS_::m_instance { nullptr };                                \
  _CLS_* _CLS_::instance() {                                           \
    static QMutex mutex;                                               \
    if (m_instance == nullptr) {                                       \
      QMutexLocker locker(&mutex);                                     \
      if (m_instance == nullptr)                                       \
        m_instance = new _CLS_;                                        \
    }                                                                  \
    return m_instance;                                                 \
  }

#define QOOL_SIMPLE_SINGLETON_QML_CREATE(_CLS_)                        \
public:                                                                \
  static _CLS_* create(QQmlEngine*, QJSEngine*) {                      \
    return _CLS_::instance();                                          \
  }

#endif // QOOLCOMMON_SINGLETON_HPP
