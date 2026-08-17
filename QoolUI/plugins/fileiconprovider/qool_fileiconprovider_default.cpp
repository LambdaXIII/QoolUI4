#include "qool_fileiconprovider_default.h"

#include "qoolcommon/debug.hpp"

#include <QFile>
#include <QFileInfo>
#include <QMutex>

QOOL_NS_BEGIN

// 类：FileIconProvider_Default
// 默认文件图标提供者插件：把本地文件路径映射到内置图标资源。
//
// 实现 `FileIconProvider` 接口的 Qt 插件（IID `QOOL_FILEICONPROVIDER_IID`）。
// 宿主经 `image://qoolfileicon/...` URL 请求图标：QML 侧
// `image://qoolfileicon/<百分号编码的文件路径>` 由 FileIconImageProvider
// 解码后，把本地文件路径作为 `id` 传入 `provideUrl()`/`providePath()`，
// 返回内置图标的 qrc URL 或路径。
//
// 索引数据库（刻意设计）
// 首次使用时懒加载 qrc 内 `:/qoolui/fileicons/index.csv`：每行
// `键,图标文件名`，键为小写单后缀，加载后排序去重。初始化采用
// 原子标志（acquire/release）加互斥锁的双检锁——`imageName` 可能被
// 异步图片加载线程并发调用，bool 非原子读写构成数据竞争（UB）。
// 行解析含防御：缺列（无逗号）的损坏行直接跳过，避免越界崩溃。
//
// 单后缀契约（刻意设计）
// 索引键是单后缀契约（如 `"png"`、`"tar"`）：`completeSuffix()` 对
// 多段后缀返回 `"tar.gz"` 之类复合串，永远无法命中键；故按
// `suffix()` 取末段后缀匹配，与索引键一一对应。
//
// 匹配顺序：目录（可读→`Folder.png`，否则 `DeleteFolder.png`）→
// 可执行（`Binary.png`）→ 单后缀命中索引 → 兜底 `File.png`。数据库
// 为空时返回 `std::nullopt`，调用侧（`FileIconDB`）按优先级回退到
// 下一个提供者。`provideUrl()` 返回 `qrc:` URL（供 QML Image 加载），
// `providePath()` 返回 `:/` 路径（供 QImage/QFile 直接打开）；二者
// 忽略 `size`——图标为固定尺寸资源，缩放由调用侧完成。

struct FileIconProvider_Default::Impl {
  QHash<QString, QString> database;
  QStringList keys;
  // 原子化：imageName 在无锁路径读取该标志（提供者可能被
  // 异步图片加载线程并发调用），bool 非原子读写构成数据竞争（UB）
  std::atomic<bool> database_initialized { false };
  QMutex database_mutex;
  void initializeDatabase() {
    if (database_initialized.load(std::memory_order_acquire)) {
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
      database_initialized.store(true, std::memory_order_release);
      return;
    }

    QTextStream stream(&index_file);
    while (! stream.atEnd()) {
      const QString line = stream.readLine();
      const auto sp = line.split(',');
      // 行解析防御：缺列（无逗号的损坏行）时 at(1) 越界崩溃
      if (sp.size() < 2)
        continue;
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

    database_initialized.store(true, std::memory_order_release);
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

    // 索引键是单后缀契约（index.csv 键如 "png"、"tar"）：completeSuffix
    // 对多段后缀返回 "tar.gz" 之类复合串，永远无法命中键 → 全部回退
    // File.png。suffix() 取末段后缀，与索引键一一对应。
    const QString suffix = fileInfo.suffix().toLower();
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