#ifndef QOOL_DEBUG_HPP
#define QOOL_DEBUG_HPP

#include <QMetaObject>
#include <QMetaProperty>
#include <QtDebug>

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

#define xDebug qDebug().noquote() << xDBGGreen << "[D]" << xDBGReset
#define xInfo qInfo().noquote() << xDBGBlue << "[I]" << xDBGReset
#define xWarning                                                       \
  qWarning().noquote() << xDBGYellow << "[W]" << xDBGReset
#define xCritical qDebug().noquote() << xDBGPink << "[C]" << xDBGReset
#define xFatal qDebug().noquote() << xDBGRed << "[F]" << xDBGReset

struct __XDBGTOKEN__ {
  const char* token;
  __XDBGTOKEN__(const char* x = nullptr) { token = x; }
};

inline QDebug operator<<(
  QDebug debug, const __XDBGTOKEN__& t) noexcept {
  if (t.token)
    debug.noquote().nospace()
      << xDBGCyan << "[" << t.token << "]" << xDBGReset;
  return debug.space();
};

#define xDBGToken(_token_) __XDBGTOKEN__(_token_)

#define xDebugQ xDebug << xDBGToken(staticMetaObject.className())
#define xInfoQ xInfo << xDBGToken(staticMetaObject.className())
#define xWarningQ xWarning << xDBGToken(staticMetaObject.className())
#define xCriticalQ xCritical << xDBGToken(staticMetaObject.className())
#define xFatalQ xFatal << xDBGToken(staticMetaObject.className())

struct __XDBGVARIANT__ {
  const QVariant& variant;
  inline QString valueString() const {
    if (variant.isNull())
      return "NULL";
    if (variant.canConvert<QString>())
      return variant.toString();
    return QString("<%1>").arg(variant.typeName());
  }
  inline QString typeName() const {
    auto result = QString::fromLatin1(variant.typeName());
    if (result.isEmpty())
      return "???";
    return result;
  }
  __XDBGVARIANT__(const QVariant& x)
    : variant(x) {}
};
inline QDebug operator<<(
  QDebug debug, const __XDBGVARIANT__& t) noexcept {
  debug.noquote().nospace()
    << xDBGWhite << xDBGGreen << t.variant.typeName() << xDBGReset
    << "(" << xDBGYellow << t.valueString() << xDBGReset << ")";
  return debug.space();
};
#define xDBGVariant(__variant__) __XDBGVARIANT__(__variant__)

template <typename K, typename V>
struct __XDBGMAP__ {
  const QMap<K, V>& map;
  __XDBGMAP__(const QMap<K, V>& x)
    : map(x) {}
};

template <typename K, typename V>
inline QDebug operator<<(
  QDebug debug, const __XDBGMAP__<K, V>& t) noexcept {
  debug.noquote().nospace()
    << xDBGBlue << "[QMap:" << xDBGReset << t.map.count() << xDBGBlue
    << "]" << xDBGReset;

  for (auto iter = t.map.constBegin(); iter != t.map.constEnd();
    ++iter) {
    debug.noquote().nospace()
      << "\n  " << xDBGYellow << iter.key() << xDBGReset << "\t\t:\t"
      << xDBGGreen << iter.value() << xDBGReset;
  }
  return debug.space();
}

template <>
inline QDebug operator<<(
  QDebug debug, const __XDBGMAP__<QString, QVariant>& t) noexcept {
  debug.noquote().nospace()
    << xDBGBlue << "[QMap : " << xDBGReset << t.map.count() << xDBGBlue
    << "]" << xDBGReset;

  for (auto iter = t.map.constBegin(); iter != t.map.constEnd();
    ++iter) {
    __XDBGVARIANT__ variant(iter.value());
    const auto line =
      QString("\n  " xDBGBlue "%1" xDBGYellow "%2" xDBGReset
              " : " xDBGGreen "%3" xDBGReset)
        .arg(variant.typeName().leftJustified(16, ' '),
          iter.key().rightJustified(30, ' '),
          variant.valueString());
    debug << line;
  }
  return debug.space();
}

#define xDBGMap(__map__) __XDBGMAP__(__map__)

struct __XDBGMETAPROPERTYLIST__ {
  QObject* object;
  const int offset, count;
  inline QMap<int, QMetaProperty> properties() const {
    auto obj = object->metaObject();
    QMap<int, QMetaProperty> result;
    for (int i = offset; i < count; ++i)
      result.insert(i, obj->property(i));
    return result;
  }
  __XDBGMETAPROPERTYLIST__(QObject* object)
    : object(object)
    , offset(object->metaObject()->propertyOffset())
    , count(object->metaObject()->propertyCount()) {}
};
inline QDebug operator<<(
  QDebug debug, const __XDBGMETAPROPERTYLIST__& x) noexcept {
  debug.noquote().nospace()
    << xDBGBlue << "[QProperty:" << xDBGYellow << x.offset << xDBGReset
    << " -> " << xDBGYellow << x.count << xDBGBlue << "]" << xDBGReset;
  const auto props = x.properties();
  for (auto iter = props.constBegin(); iter != props.constEnd();
    ++iter) {
    const QString index_s =
      QString::number(iter.key()).leftJustified(3, ' ');
    const QString name_s =
      QString(iter.value().name()).rightJustified(20, ' ');
    const __XDBGVARIANT__ vairnat(iter.value().read(x.object));
    const QString type_s = vairnat.typeName().leftJustified(14, ' ');
    const QString value_s = vairnat.valueString();
    QString line = QString("  \n" xDBGBlue "[%0]%1" xDBGYellow
                           "%2" xDBGBlue " : " xDBGGreen "%3" xDBGReset)
                     .arg(index_s, type_s, name_s, value_s);
    debug << line;
  } // for
  return debug.space();
}

#define xDBGQPropertyList __XDBGMETAPROPERTYLIST__(this)

#endif // QOOL_DEBUG_HPP
