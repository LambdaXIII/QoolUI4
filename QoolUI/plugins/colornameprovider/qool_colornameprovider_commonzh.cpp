#include "qool_colornameprovider_commonzh.h"

#include <QColor>
#include <QFile>
#include <QReadWriteLock>
#include <QTextStream>

QOOL_NS_BEGIN

class CommonZhColorNameProvider::Impl {
  QReadWriteLock m_lock;
  QHash<QString, QoolRGBA> m_colors;
  bool m_loaded { false };

public:
  void load_colors() {
    if (m_loaded)
      return;
    QWriteLocker locker(&m_lock);
    m_colors.clear();
    QFile names(":/qoolui/colors/common_zh.csv");
    if (! names.open(QFile::ReadOnly | QFile::Text)) {
      return;
    }
    QTextStream stream(&names);
    while (! stream.atEnd()) {
      const QString line = stream.readLine();
      const QStringList parts = line.split(',');
      const QString n = parts[0];
      const qreal r = parts[1].toFloat() / 255.0;
      const qreal g = parts[2].toFloat() / 255.0;
      const qreal b = parts[3].toFloat() / 255.0;
      m_colors.insert(n, { r, g, b, 1 });
    }
    names.close();
    m_loaded = true;
  }

  const QHash<QString, QoolRGBA>& colors() {
    QReadLocker locker(&m_lock);
    return m_colors;
  }
};

CommonZhColorNameProvider::CommonZhColorNameProvider()
  : QObject { nullptr }
  , QOOL_NS::ColorNameProvider() {
  m_impl = new Impl;
  m_impl->load_colors();
}

CommonZhColorNameProvider::~CommonZhColorNameProvider() {
  if (m_impl)
    delete m_impl;
}

QString CommonZhColorNameProvider::category() const {
  return "CommonZh";
}

QStringList CommonZhColorNameProvider::names() const {
  return m_impl->colors().keys();
}

std::optional<ColorNameProvider::QoolRGBA>
  CommonZhColorNameProvider::color(const QString& name) const {
  if (! m_impl->colors().contains(name))
    return {};
  return std::make_optional(m_impl->colors().value(name));
}

std::optional<QString> CommonZhColorNameProvider::name(
  const QoolRGBA& rgba) const {
  const QString k = m_impl->colors().key(rgba, {});
  if (k.isEmpty())
    return {};
  return { k };
}

QOOL_NS_END
