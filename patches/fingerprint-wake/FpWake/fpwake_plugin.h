#ifndef FPWAKE_H
#define FPWAKE_H
#include <QObject>
#include <QQmlExtensionPlugin>
#include <QVariantList>
class FpWake : public QObject {
    Q_OBJECT
public:
    explicit FpWake(QObject *parent = nullptr) : QObject(parent) {}
    Q_INVOKABLE void wakeScreen();
    Q_INVOKABLE void setBrightness(int value);
    Q_INVOKABLE void openSettings();
    Q_INVOKABLE QString wifiSsid();
    Q_INVOKABLE QString btDevice();
    Q_INVOKABLE void wifiToggle();
    Q_INVOKABLE void btToggle();
    Q_INVOKABLE bool wifiEnabled();
    Q_INVOKABLE bool btEnabled();
    Q_INVOKABLE QVariantList wifiNetworks();
    Q_INVOKABLE void wifiConnect(const QString &ssid);
};
class FpWakePlugin : public QQmlExtensionPlugin {
    Q_OBJECT
    Q_PLUGIN_METADATA(IID "org.qt-project.Qt.QQmlExtensionInterface")
public:
    void registerTypes(const char *uri) override;
};
#endif
