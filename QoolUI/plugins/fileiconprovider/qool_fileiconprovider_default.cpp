#include "qool_fileiconprovider_default.h"

#include "qoolcommon/debug.hpp"

#include <QFile>
#include <QFileInfo>
#include <QMutex>

QOOL_NS_BEGIN

struct FileIconProvider_Default::Impl {
  QHash<QString, QString> database;
  QStringList keys;
  bool database_initialized = false;
  QMutex database_mutex;
  void initializeDatabase() {
    if (database_initialized) {
      xWarning << xDBGToken("QoolUIFileIconProvider")
               << "database already initialized, check possible bugs.";
      return;
    }
    QMutexLocker locker(&database_mutex);
    QFile index_file(":/qoolui/fileicons/index.csv");
    if (! index_file.open(QIODevice::Text | QIODevice::ReadOnly)) {
      xWarning
        << xDBGToken("QoolUIFileIconProvider")
        << "Cannot load index of icons, the plugin might be corrupted.";
      database_initialized = true;
      return;
    }

    QTextStream stream(&index_file);
    while (! stream.atEnd()) {
      const QString line = stream.readLine();
      auto sp = line.split(',');
      const auto key = sp.at(0).toLower();
      keys << key;
      database.insert(key, sp.at(1));
    }
    xInfo << xDBGToken("QoolUIFileIconProvider") << database.count()
          << "icons loaded.";

    std::sort(keys.begin(), keys.end());
    auto last = std::unique(keys.begin(), keys.end());
    keys.erase(last, keys.end());
    keys.shrink_to_fit();

    database_initialized = true;
  }

  QString imageName(const QFileInfo& fileInfo) {
    if (! database_initialized)
      initializeDatabase();

    if (database.isEmpty()) {
      xWarning
        << xDBGToken("QoolUIFileIconProvider")
        << "Database is empty, check if the plugin is initialized "
           "properly.";
      return {};
    }

    if (fileInfo.isDir())
      return fileInfo.isReadable() ? "Folder.png" : "DeleteFolder.png";

    if (fileInfo.isExecutable())
      return "Binary.png";

    const QString suffix = fileInfo.completeSuffix().toLower();
    auto found = std::find_if(keys.cbegin(), keys.cend(),
      [&](const QString& k) { return k == suffix; });
    if (found != keys.cend())
      return database.value(*found);
    return "File.png";
  }
}; // impl

FileIconProvider_Default::FileIconProvider_Default(QObject* parent)
  : QObject(parent)
  , FileIconProvider()
  , m_pImpl { new Impl } {
}

FileIconProvider_Default::~FileIconProvider_Default() {
  delete m_pImpl;
}

std::optional<QUrl> FileIconProvider_Default::provideUrl(
  QAnyStringView id, const QSize& size) const {
  Q_UNUSED(size)
  const QFileInfo info(id.toString());
  const QString image = m_pImpl->imageName(info);
  if (image.isEmpty())
    return std::nullopt;

  static const QString url_pattern { QStringLiteral(
    "qrc:/qoolui/fileicons/%1") };

  return QUrl(url_pattern.arg(image));
}

std::optional<QString> FileIconProvider_Default::providePath(
  QAnyStringView id, const QSize& size) const {
  Q_UNUSED(size)
  const QFileInfo info(id.toString());
  const QString image = m_pImpl->imageName(info);
  if (image.isEmpty())
    return std::nullopt;

  static const QString path_pattern { QStringLiteral(
    ":/qoolui/fileicons/%1") };

  return path_pattern.arg(image);
}

QOOL_NS_END