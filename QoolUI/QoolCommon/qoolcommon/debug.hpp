#ifndef QOOLCOMMON_DEBUG_HPP
#define QOOLCOMMON_DEBUG_HPP

// QoolCommon 调试打印设施。用法与门控说明见
// docs/reference/QoolCommon/debug.md。
//
// 分层结构（为什么这样分）：
// - 入口（xDebug/xDebugQ 等）必须保留为宏：只有宏能在调用点做
//   条件编译（Release 抹除）和文本注入 `this`；流式链的参数求值
//   无法抹除，这是 `<<` 表达式的本质约束（Qt 的 QT_NO_DEBUG_OUTPUT
//   同样如此）。
// - 包装器（xDBGList/xDBGMap 等）是命名空间内的函数模板，宏名仅作
//   零参转发；concept 门禁给出可读的编译错误。
// - 颜色宏必须保留：67+ 调用点依赖字面量拼接（xDBGYellow "text"）。

#include "qoolns.hpp"

#include <QObject>
#include <QMetaProperty>
#include <QVariant>
#include <QtDebug>

#include <concepts>
#include <ranges>
#include <tuple>
#include <type_traits>
#include <utility>

// ------------------------------------------------------------------
// ANSI 颜色宏（稳定 API：字面量拼接依赖宏展开，勿改为变量）
// ------------------------------------------------------------------

#define xDBGReset "\033[0m"

#define xDBGBlack "\033[30m"
#define xDBGBlackBG "\033[40m"
#define xDBGRed "\033[31m"
#define xDBGRedBG "\033[41m"
#define xDBGGreen "\033[32m"
#define xDBGGreenBG "\033[42m"
#define xDBGYellow "\033[33m"
#define xDBGYellowBG "\033[43m"
#define xDBGBlue "\033[34m"
#define xDBGBlueBG "\033[44m"
#define xDBGPink "\033[35m"
#define xDBGPinkBG "\033[45m"
#define xDBGCyan "\033[36m"
#define xDBGCyanBG "\033[46m"
#define xDBGWhite "\033[37m"
#define xDBGWhiteBG "\033[47m"

#define xDBGLightBlack "\033[90m"
#define xDBGLightBlackBG "\033[100m"
#define xDBGLightRed "\033[91m"
#define xDBGLightRedBG "\033[101m"
#define xDBGLightGreen "\033[92m"
#define xDBGLightGreenBG "\033[102m"
#define xDBGLightYellow "\033[93m"
#define xDBGLightYellowBG "\033[103m"
#define xDBGLightBlue "\033[94m"
#define xDBGLightBlueBG "\033[104m"
#define xDBGLightPink "\033[95m"
#define xDBGLightPinkBG "\033[105m"
#define xDBGLightCyan "\033[96m"
#define xDBGLightCyanBG "\033[106m"
#define xDBGLightWhite "\033[97m"
#define xDBGLightWhiteBG "\033[107m"

#define xDBGGrey xDBGLightBlack
#define xDBGGreyBG xDBGLightBlackBG
#define xDBGBold "\033[1m"
#define xDBGUnderLine "\033[4m"

#define xDBGStyle(_style_, _content_) _style_ << _content_ << xDBGReset

QOOL_NS_BEGIN

namespace debug {

// ------------------------------------------------------------------
// xDBGToken：打印 [token] 前缀
// ------------------------------------------------------------------

struct Token {
  const char* token;
};

inline QDebug operator<<(QDebug debug, const Token& t) noexcept {
  if (t.token)
    debug.noquote().nospace()
      << xDBGCyan << "[" << t.token << "]" << xDBGReset;
  return debug.space();
}

inline Token xDBGToken(const char* token) { return Token{token}; }

// ------------------------------------------------------------------
// 入口实现（函数形式；宏层负责门控与 this 注入）
// ------------------------------------------------------------------

inline QDebug xDebug() {
  return qDebug().noquote() << xDBGGreen << "[D]" << xDBGReset;
}

inline QDebug xInfo() {
  return qInfo().noquote() << xDBGBlue << "[I]" << xDBGReset;
}

inline QDebug xWarning() {
  return qWarning().noquote() << xDBGYellow << "[W]" << xDBGReset;
}

inline QDebug xCritical() {
  return qCritical().noquote() << xDBGPink << "[C]" << xDBGReset;
}

// Q 后缀实现用 staticMetaObject 而非 QObject 转型：调用点包括
// QGADGET 类型（如 Theme/Message），它们有元对象但不是 QObject 派生。
template <typename T>
inline QDebug xDebugQ(const T* object) {
  return xDebug() << xDBGToken(object->staticMetaObject.className());
}

template <typename T>
inline QDebug xInfoQ(const T* object) {
  return xInfo() << xDBGToken(object->staticMetaObject.className());
}

template <typename T>
inline QDebug xWarningQ(const T* object) {
  return xWarning() << xDBGToken(object->staticMetaObject.className());
}

template <typename T>
inline QDebug xCriticalQ(const T* object) {
  return xCritical() << xDBGToken(object->staticMetaObject.className());
}

// ------------------------------------------------------------------
// Release 门控的接收端：吞掉整条 << 链，包装器不被遍历
// ------------------------------------------------------------------

struct NoDebug {
  template <typename T>
  const NoDebug& operator<<(const T&) const noexcept {
    return *this;
  }
  const NoDebug& noquote() const noexcept { return *this; }
  const NoDebug& nospace() const noexcept { return *this; }
  const NoDebug& space() const noexcept { return *this; }
};

// ------------------------------------------------------------------
// xDBGVariant：打印类型名(值)；null 值回退 "???" / "NULL"
// ------------------------------------------------------------------

struct VariantW {
  QVariant variant;

  inline QString valueString() const {
    if (variant.isNull())
      return "NULL";
    if (! variant.canConvert<QString>())
      return QString("<%1>").arg(variant.typeName());
    return variant.toString();
  }
  inline QString typeName() const {
    auto result = QString::fromLatin1(variant.typeName());
    if (result.isEmpty())
      return "???";
    return result;
  }
};

inline QDebug operator<<(QDebug debug, const VariantW& t) noexcept {
  debug.noquote().nospace()
    << xDBGGreen << t.typeName() << xDBGReset
    << "(" << xDBGYellow << t.valueString() << xDBGReset << ")";
  return debug.space();
}

inline VariantW xDBGVariant(const QVariant& variant) {
  return VariantW{variant};
}

// ------------------------------------------------------------------
// xDBGList：一维容器打印。
// 元素为字符类型（char/QChar/wchar_t）的 range 视为字符串，不接纳。
// ------------------------------------------------------------------

template <typename R>
concept CharValueRange =
  std::same_as<std::ranges::range_value_t<R>, char> ||
  std::same_as<std::ranges::range_value_t<R>, QChar> ||
  std::same_as<std::ranges::range_value_t<R>, wchar_t>;

template <typename R>
concept Range1D = std::ranges::forward_range<R> &&
  !CharValueRange<std::remove_cvref_t<R>>;

template <Range1D R>
struct ListW {
  const R& range;
};

template <Range1D R>
inline QDebug operator<<(QDebug debug, const ListW<R>& w) noexcept {
  // forward_range 允许两遍遍历：先取长度定对齐宽度，再逐项输出
  const auto len = static_cast<int>(std::ranges::distance(w.range));
  const int max_index_length = QString::number(len).length();
  debug.noquote().nospace()
    << xDBGBlue << "[List:" << len << "]" << xDBGReset;
  int index = 0;
  for (const auto& element : w.range) {
    const QString index_text =
      QString::number(index).leftJustified(max_index_length, ' ');
    debug << "\n"
          << xDBGYellow << "[" << index_text << "] " << xDBGGreen
          << element << xDBGReset;
    ++index;
  }
  return debug.space();
}

template <Range1D R>
inline ListW<R> xDBGList(const R& range) { return ListW<R>{range}; }

// ------------------------------------------------------------------
// xDBGMap：键值对容器打印。
// 元素为 pair-like（tuple_size==2 且 get<0>/get<1> 可用）的 range，
// 或提供 asKeyValueRange() 的 Qt 容器（QMap/QHash/QMultiMap/QMultiHash
// 的迭代器解引用只给映射值，pair 视图必须经 asKeyValueRange()）。
// ------------------------------------------------------------------

template <typename T>
concept PairLike = requires(const T& t) {
  typename std::tuple_element<0, T>;
  typename std::tuple_element<1, T>;
  { std::get<0>(t) };
  { std::get<1>(t) };
  std::tuple_size<T>::value == 2;
};

template <typename R>
concept MapLike = std::ranges::forward_range<R> &&
  (PairLike<std::ranges::range_value_t<std::remove_cvref_t<R>>> ||
   requires(const R& r) { r.asKeyValueRange(); });

template <MapLike M>
struct MapW {
  const M& map;
};

template <MapLike M>
inline QDebug operator<<(QDebug debug, const MapW<M>& w) noexcept {
  // Qt 容器经 asKeyValueRange() 物化 pair 视图；STL 容器自身即
  // pair range。语句内临时对象在完整表达式结束前存活，无悬垂。
  auto kv = [&]() -> decltype(auto) {
    if constexpr (requires { w.map.asKeyValueRange(); })
      return w.map.asKeyValueRange();
    else
      return (w.map);
  }();
  using K = std::remove_cvref_t<
    std::tuple_element_t<0, std::ranges::range_value_t<decltype(kv)>>>;
  using V = std::remove_cvref_t<
    std::tuple_element_t<1, std::ranges::range_value_t<decltype(kv)>>>;

  debug.noquote().nospace()
    << xDBGBlue << "[Map:" << xDBGReset << std::ranges::distance(kv)
    << xDBGBlue << "]" << xDBGReset;

  for (const auto& [key, value] : kv) {
    if constexpr (std::same_as<K, QString> && std::same_as<V, QVariant>) {
      const VariantW variant(value);
      const QString line =
        QString("\n  " xDBGBlue "%1" xDBGYellow "%2" xDBGReset
                " : " xDBGGreen "%3" xDBGReset)
          .arg(variant.typeName().leftJustified(16, ' '),
            key.rightJustified(30, ' '), variant.valueString());
      debug << line;
    } else {
      debug.noquote().nospace()
        << "\n  " << xDBGYellow << key << xDBGReset << "\t:\t"
        << xDBGGreen << value << xDBGReset;
    }
  }
  return debug.space();
}

template <MapLike M>
inline MapW<M> xDBGMap(const M& map) { return MapW<M>{map}; }

// ------------------------------------------------------------------
// xDBGQPropertyList：打印对象自身（propertyOffset 起）的元属性
// ------------------------------------------------------------------

struct PropertyListW {
  const QObject* object;
  const int offset, count;

  inline QMap<int, QMetaProperty> properties() const {
    auto meta = object->metaObject();
    QMap<int, QMetaProperty> result;
    for (int i = offset; i < count; ++i)
      result.insert(i, meta->property(i));
    return result;
  }
};

inline PropertyListW xDBGPropertyList(const QObject* object) {
  const auto meta = object->metaObject();
  return PropertyListW{
    object, meta->propertyOffset(), meta->propertyCount()};
}

inline QDebug operator<<(QDebug debug, const PropertyListW& x) noexcept {
  debug.noquote().nospace()
    << xDBGBlue << "[Prop:" << xDBGYellow << x.offset << xDBGReset
    << " -> " << xDBGYellow << x.count - 1 << xDBGBlue << "]"
    << xDBGReset;
  const auto props = x.properties();
  for (auto iter = props.constBegin(); iter != props.constEnd(); ++iter) {
    const QString index_s =
      QString::number(iter.key()).leftJustified(3, ' ');
    const QString name_s =
      QString(iter.value().name()).rightJustified(20, ' ');
    const VariantW variant(iter.value().read(x.object));
    const QString type_s = variant.typeName().leftJustified(14, ' ');
    const QString value_s = variant.valueString();
    const QString line =
      QString("  \n" xDBGBlue "%0 %1" xDBGYellow "%2" xDBGBlue " : "
              xDBGGreen "%3" xDBGReset)
        .arg(index_s, type_s, name_s, value_s);
    debug << line;
  } // for
  return debug.space();
}

} // namespace debug

QOOL_NS_END

// ==================================================================
// 宏 API 层（调用点唯一入口）
// - 门控：定义 XDBG_NO_DEBUG / XDBG_NO_INFO / XDBG_NO_WARNING 抹除
//   对应级别；同时尊重 QT_NO_DEBUG_OUTPUT / QT_NO_WARNING_OUTPUT。
//   xCritical 不提供抹除（严重级别永远编译）。
// - Q 后缀宏在启用态文本注入 `this`，调用点保持无参旧形式
//   （xDebugQ << ... 仅在成员函数/成员 lambda 中可用，与旧版一致）。
// - 抹除态参数仍会被求值（流式链的表达式本质）；日志参数应为纯表达式。
// ==================================================================

#if defined(XDBG_NO_DEBUG) || defined(QT_NO_DEBUG_OUTPUT)
#  define xDebug QOOL_NS::debug::NoDebug{}
#else
#  define xDebug QOOL_NS::debug::xDebug()
#endif

#if defined(XDBG_NO_INFO)
#  define xInfo QOOL_NS::debug::NoDebug{}
#else
#  define xInfo QOOL_NS::debug::xInfo()
#endif

#if defined(XDBG_NO_WARNING) || defined(QT_NO_WARNING_OUTPUT)
#  define xWarning QOOL_NS::debug::NoDebug{}
#else
#  define xWarning QOOL_NS::debug::xWarning()
#endif

#define xCritical QOOL_NS::debug::xCritical()

#if defined(XDBG_NO_DEBUG) || defined(QT_NO_DEBUG_OUTPUT)
#  define xDebugQ QOOL_NS::debug::NoDebug{}
#else
#  define xDebugQ QOOL_NS::debug::xDebugQ(this)
#endif

#if defined(XDBG_NO_INFO)
#  define xInfoQ QOOL_NS::debug::NoDebug{}
#else
#  define xInfoQ QOOL_NS::debug::xInfoQ(this)
#endif

#if defined(XDBG_NO_WARNING) || defined(QT_NO_WARNING_OUTPUT)
#  define xWarningQ QOOL_NS::debug::NoDebug{}
#else
#  define xWarningQ QOOL_NS::debug::xWarningQ(this)
#endif

#define xCriticalQ QOOL_NS::debug::xCriticalQ(this)

#define xDBGToken(_token_) QOOL_NS::debug::xDBGToken(_token_)
#define xDBGVariant(_variant_) QOOL_NS::debug::xDBGVariant(_variant_)
#define xDBGList(_list_) QOOL_NS::debug::xDBGList(_list_)
#define xDBGMap(_map_) QOOL_NS::debug::xDBGMap(_map_)
#define xDBGQPropertyList QOOL_NS::debug::xDBGPropertyList(this)

#endif // QOOLCOMMON_DEBUG_HPP
