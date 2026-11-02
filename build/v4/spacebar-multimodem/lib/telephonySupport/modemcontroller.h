// SPDX-FileCopyrightText: 2021 Nicolas Fella <nicolas.fella@gmx.de>
//
// SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
#pragma once

#include <QDBusPendingReply>
#include <QHash>
#include <QObject>

#include <optional>

#include <ModemManagerQt/Modem3Gpp>
#include <ModemManagerQt/ModemDevice>
#include <ModemManagerQt/ModemMessaging>
#include <ModemManagerQt/Sms>

class ModemController : public QObject
{
    Q_OBJECT
public:
    static ModemController &instance();

    void init(std::optional<QString> modemPath);

    std::optional<QDBusPendingReply<QDBusObjectPath>> createMessage(ModemManager::ModemMessaging::Message m);
    void deleteMessage(const QString &uni);
    // m52xq: 1 / 2 = the SIM the next createMessage() goes through (0 = automatic)
    void setNextSim(int sim);
    // m52xq: SIM (1 / 2, 0 = unknown) the received message came over / the last createMessage() went through
    int simOfMessage(const QString &uni) const;
    int lastCreatedSim() const;
    // sidecar ~/.local/share/spacebar/message-sim: "in:<ms>" / "out:<id>" -> SIM, read by the app to label the messages
    static void recordSim(const QString &key, int sim);

    ModemManager::Sms::List messages();

    QString ownNumber();

    QString ifaceName;

    QString dnsServers;

    QString countryCode;

Q_SIGNALS:
    void messageAdded(ModemManager::Sms::Ptr message);
    void modemConnected();
    void modemDataConnectedChanged(const bool isConnected);
    void countryCodeChanged(const QString &code);

private Q_SLOTS:
    void slotMessageAdded(const QString &uni, bool received);

private:
    void initMessaging();
    // m52xq: dual-SIM, SMS of every modem (the stock code follows modemDevices().first() only)
    void attachMessaging(const ModemManager::ModemDevice::Ptr &dev);
    void attachAllMessaging();
    void handleMessage(const ModemManager::ModemMessaging::Ptr &mgr, const QString &uni, bool received);
    QList<ModemManager::ModemMessaging::Ptr> m_msgManagers;
    QList<QString> m_msgDevices; // modem device name (e.g. qcom-soc-sim2) of each entry of m_msgManagers
    // m52xq: which modem (SIM) a reply goes through: last SIM a number wrote to us on / sent over, else /etc/m52xq/sms-sim, else the first modem
    ModemManager::ModemMessaging::Ptr managerForNumber(const QString &number);
    void rememberNumber(const QString &number, const QString &device);
    void loadSimMap();
    QHash<QString, QString> m_numberDevice;
    QString m_simMapPath;
    int m_nextSim = 0;
    int m_lastCreatedSim = 0;
    QHash<QString, QString> m_uniDevice;
    QList<QString> m_watchedModems;
    ModemController();

    ModemManager::ModemDevice::Ptr m_modem;
    ModemManager::ModemMessaging::Ptr m_msgManager;
    ModemManager::Modem::Ptr m_interface;
    ModemManager::Bearer::Ptr m_bearer;
    ModemManager::Modem3gpp::Ptr m_modem3gpp;

    QString getDNS(QSharedPointer<ModemManager::Bearer> bearer);
};
