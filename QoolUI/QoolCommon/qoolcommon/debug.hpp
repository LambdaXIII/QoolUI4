#ifndef QOOL_DEBUG_HPP
#define QOOL_DEBUG_HPP

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

#endif // QOOL_DEBUG_HPP
