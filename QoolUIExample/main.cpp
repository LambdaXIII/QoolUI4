#include <QDebug>
#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QTranslator>

int main(int argc, char* argv[]) {
  QGuiApplication app(argc, argv);

  // QTranslator translator;
  // if (translator.load(QLocale(), "qoolexample", "_", ":/i18n"))
  //   app.installTranslator(&translator);

  QTranslator zh, en;
  if (zh.load("qoolexample.en", ":/qoolexample/i18n"))
    app.installTranslator(&en);
  if (zh.load("qoolexample.zh", ":/qoolexample/i18n"))
    app.installTranslator(&zh);

  QQmlApplicationEngine engine;
  engine.addImportPath(QStringLiteral("qml"));

  QObject::connect(
    &engine, &QQmlApplicationEngine::objectCreationFailed, &app,
    []() { QCoreApplication::exit(-1); }, Qt::QueuedConnection);
  engine.loadFromModule("QoolUIExample", "Main");

  return app.exec();
}
