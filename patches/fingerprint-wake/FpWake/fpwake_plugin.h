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
    Q_INVOKABLE void setAutoBrightness(bool enabled);
    Q_INVOKABLE bool getAutoBrightness();
    Q_INVOKABLE int getBrightness();
    Q_INVOKABLE void setVolume(int percent);
    Q_INVOKABLE void setMute(bool muted);
    Q_INVOKABLE int getVolume();
    Q_INVOKABLE bool getMute();
    Q_INVOKABLE void toggleFlashlight();
    Q_INVOKABLE bool getFlashlight();
    Q_INVOKABLE void setRotationLock(bool locked);
    Q_INVOKABLE bool getRotationLock();
    Q_INVOKABLE void toggleLocation();
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
