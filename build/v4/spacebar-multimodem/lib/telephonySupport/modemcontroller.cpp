// SPDX-FileCopyrightText: 2021 Nicolas Fella <nicolas.fella@gmx.de>
//
// SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL

#include "modemcontroller.h"

#include <ModemManagerQt/Manager>

#include <QFile>
#include <QStandardPaths>
#include <QTextStream>

ModemController &ModemController::instance()
{
    static ModemController instance;
    return instance;
}

ModemController::ModemController()
    : QObject()
{
    connect(ModemManager::notifier(), &ModemManager::Notifier::modemAdded, this, [this](const QString &udi) {
        init(udi);
    });
}

std::optional<QDBusPendingReply<QDBusObjectPath>> ModemController::createMessage(ModemManager::ModemMessaging::Message m)
{
    ModemManager::ModemMessaging::Ptr mgr;
    if (m_nextSim > 0) {
        for (int i = 0; i < m_msgDevices.size(); ++i) {
            if (m_msgDevices.at(i).endsWith(QLatin1String("sim2")) == (m_nextSim == 2)) {
                mgr = m_msgManagers.value(i);
                rememberNumber(m.number, m_msgDevices.at(i));
                break;
            }
        }
        m_nextSim = 0;
    }
    if (!mgr) {
        mgr = managerForNumber(m.number);
    }
    if (!mgr) {
        mgr = m_msgManager;
    }
    if (!mgr) {
        return {};
    }
    const int di = m_msgManagers.indexOf(mgr);
    m_lastCreatedSim = di >= 0 ? (m_msgDevices.value(di).endsWith(QLatin1String("sim2")) ? 2 : 1) : 0;

    return mgr->createMessage(m);
}

void ModemController::setNextSim(int sim)
{
    m_nextSim = sim;
}

int ModemController::simOfMessage(const QString &uni) const
{
    const QString dev = m_uniDevice.value(uni);
    return dev.isEmpty() ? 0 : (dev.endsWith(QLatin1String("sim2")) ? 2 : 1);
}

int ModemController::lastCreatedSim() const
{
    return m_lastCreatedSim;
}

void ModemController::recordSim(const QString &key, int sim)
{
    if (sim <= 0) {
        return;
    }
    const QString dir = QStandardPaths::writableLocation(QStandardPaths::GenericDataLocation) + QStringLiteral("/spacebar");
    QFile f(dir + QStringLiteral("/message-sim"));
    if (f.open(QIODevice::Append | QIODevice::Text)) {
        QTextStream out(&f);
        out << key << QLatin1Char(' ') << sim << QLatin1Char('\n');
    }
}

static QString simKey(const QString &number)
{
    QString d;
    for (const QChar c : number) {
        if (c.isDigit()) {
            d += c;
        }
    }
    return d.right(9);
}

void ModemController::loadSimMap()
{
    if (!m_simMapPath.isEmpty()) {
        return;
    }
    m_simMapPath = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation) + QStringLiteral("/sim-map");
    QFile f(m_simMapPath);
    if (f.open(QIODevice::ReadOnly | QIODevice::Text)) {
        QTextStream in(&f);
        while (!in.atEnd()) {
            const QStringList parts = in.readLine().split(QLatin1Char(' '));
            if (parts.size() == 2) {
                m_numberDevice.insert(parts[0], parts[1]);
            }
        }
    }
}

void ModemController::rememberNumber(const QString &number, const QString &device)
{
    loadSimMap();
    const QString key = simKey(number);
    if (key.isEmpty() || device.isEmpty() || m_numberDevice.value(key) == device) {
        return;
    }
    m_numberDevice.insert(key, device);
    QFile f(m_simMapPath);
    if (f.open(QIODevice::WriteOnly | QIODevice::Text | QIODevice::Truncate)) {
        QTextStream out(&f);
        for (auto it = m_numberDevice.constBegin(); it != m_numberDevice.constEnd(); ++it) {
            out << it.key() << QLatin1Char(' ') << it.value() << QLatin1Char('\n');
        }
    }
}

ModemManager::ModemMessaging::Ptr ModemController::managerForNumber(const QString &number)
{
    loadSimMap();
    QString device = m_numberDevice.value(simKey(number));
    if (device.isEmpty()) {
        // default SIM for numbers we have no history with: "1" or "2" in /etc/m52xq/sms-sim
        QFile f(QStringLiteral("/etc/m52xq/sms-sim"));
        if (f.open(QIODevice::ReadOnly | QIODevice::Text)) {
            const QString sim = QString::fromUtf8(f.readAll()).trimmed();
            for (const QString &d : std::as_const(m_msgDevices)) {
                if ((sim == QLatin1String("2")) == d.endsWith(QLatin1String("sim2"))) {
                    device = d;
                    break;
                }
            }
        }
    }
    const int idx = m_msgDevices.indexOf(device);
    if (idx >= 0) {
        if (!number.isEmpty()) {
            rememberNumber(number, device);
        }
        return m_msgManagers.value(idx);
    }
    return {};
}

void ModemController::init(std::optional<QString> modemPath)
{
    if (modemPath) {
        m_modem = ModemManager::findModemDevice(*modemPath);
    } else {
        ModemManager::ModemDevice::List devices = ModemManager::modemDevices();
        if (!devices.isEmpty()) {
            m_modem = devices.first();
        }
    }

    if (!m_modem) {
        qWarning() << "Could not find modem" << modemPath.value_or(QString());
        return;
    }

    if (m_modem->hasInterface(ModemManager::ModemDevice::GsmInterface)) {
        m_modem3gpp = m_modem->interface(ModemManager::ModemDevice::GsmInterface).objectCast<ModemManager::Modem3gpp>();
        countryCode = m_modem3gpp->countryCode();
        qDebug() << "Country Code:" << countryCode;

        connect(m_modem3gpp.get(), &ModemManager::Modem3gpp::countryCodeChanged, this, [this](const QString &code) {
            countryCode = code;
            Q_EMIT countryCodeChanged(code);
            qDebug() << "country code changed" << code;
        });

        if (countryCode.isEmpty()) {
            qWarning() << "Country code is null! Phone numbers may not be interpreted correctly";
        }
    }

    m_interface = m_modem->modemInterface();

    connect(m_interface.get(), &ModemManager::Modem::bearerAdded, this, [this](const QString &bearer) {
        m_bearer = m_interface->findBearer(bearer);
        QList<QSharedPointer<ModemManager::Bearer>> bearers = m_interface->listBearers();

        // whether or not the bearer is connected and thus whether packet data communication using this bearer is possible
        connect(m_bearer.data(), &ModemManager::Bearer::connectedChanged, this, [this](bool isConnected) {
            Q_EMIT modemDataConnectedChanged(isConnected);
            qDebug() << "bearer connected:" << isConnected;
        });

        // In some devices, packet data service will be suspended while the device is handling other communication, like a voice call
        connect(m_bearer.data(), &ModemManager::Bearer::suspendedChanged, this, [this](bool isSuspended) {
            Q_EMIT modemDataConnectedChanged(!isSuspended);
            qDebug() << "bearer suspended:" << isSuspended;
        });

        dnsServers = getDNS(m_bearer);
        qDebug() << "dns:" << dnsServers;
        connect(m_bearer.data(), &ModemManager::Bearer::ip4ConfigChanged, this, [this, bearers](const ModemManager::IpConfig &ipv4Config) {
            dnsServers = getDNS(m_bearer);
            qDebug() << "dns4 updated:" << dnsServers;
        });

        connect(m_bearer.data(), &ModemManager::Bearer::ip6ConfigChanged, this, [this, bearers](const ModemManager::IpConfig &ipv6Config) {
            dnsServers = getDNS(m_bearer);
            qDebug() << "dns6 updated:" << dnsServers;
        });

        ifaceName = m_bearer->interface();
        qDebug() << "interface:" << ifaceName;
        connect(m_bearer.data(), &ModemManager::Bearer::interfaceChanged, this, [this](const QString &iface) {
            ifaceName = iface;
            qDebug() << "interface changed:" << ifaceName;
        });
    });

    connect(m_modem.get(), &ModemManager::ModemDevice::interfaceAdded, this, [this](ModemManager::ModemDevice::InterfaceType type) {
        if (type == ModemManager::ModemDevice::MessagingInterface) {
            initMessaging();
        }
    });

    if (m_modem->hasInterface(ModemManager::ModemDevice::MessagingInterface)) {
        initMessaging();
    }

    connect(m_interface.get(), &ModemManager::Modem::stateChanged, this, [this](MMModemState oldState, MMModemState newState, MMModemStateChangeReason reason) {
        Q_UNUSED(oldState);
        Q_UNUSED(reason);
        if (newState == MMModemState::MM_MODEM_STATE_CONNECTED) {
            Q_EMIT modemConnected();
            Q_EMIT modemDataConnectedChanged(m_bearer ? m_bearer->isConnected() : false);
        }
    });
}

void ModemController::initMessaging()
{
    Q_ASSERT(m_modem);
    Q_ASSERT(m_modem->hasInterface(ModemManager::ModemDevice::MessagingInterface));

    m_msgManager = m_modem->messagingInterface();

    attachAllMessaging();

    Q_EMIT modemConnected();
}

void ModemController::attachMessaging(const ModemManager::ModemDevice::Ptr &dev)
{
    ModemManager::ModemMessaging::Ptr mgr = dev->messagingInterface();
    if (!mgr || m_msgManagers.contains(mgr)) {
        return;
    }
    m_msgManagers.append(mgr);
    m_msgDevices.append(dev->modemInterface()->device());
    connect(mgr.get(), &ModemManager::ModemMessaging::messageAdded, this, [this, mgr](const QString &uni, bool received) {
        handleMessage(mgr, uni, received);
    });
}

void ModemController::attachAllMessaging()
{
    const ModemManager::ModemDevice::List devices = ModemManager::modemDevices();
    for (const ModemManager::ModemDevice::Ptr &dev : devices) {
        if (dev->hasInterface(ModemManager::ModemDevice::MessagingInterface)) {
            attachMessaging(dev);
        } else if (!m_watchedModems.contains(dev->uni())) {
            m_watchedModems.append(dev->uni());
            connect(dev.get(), &ModemManager::ModemDevice::interfaceAdded, this, [this, dev](ModemManager::ModemDevice::InterfaceType type) {
                if (type == ModemManager::ModemDevice::MessagingInterface) {
                    attachMessaging(dev);
                    Q_EMIT modemConnected();
                }
            });
        }
    }
}

void ModemController::slotMessageAdded(const QString &uni, bool received)
{
    handleMessage(m_msgManager, uni, received);
}

void ModemController::handleMessage(const ModemManager::ModemMessaging::Ptr &mgr, const QString &uni, bool received)
{
    // true if the message was received from the network, as opposed to being added locally
    if (!received || !mgr) {
        return;
    }

    ModemManager::Sms::Ptr msg = mgr->findMessage(uni);
    if (!msg) {
        return;
    }

    const int idx = m_msgManagers.indexOf(mgr);
    if (idx >= 0) {
        rememberNumber(msg->number(), m_msgDevices.value(idx));
        m_uniDevice.insert(msg->uni(), m_msgDevices.value(idx));
    }

    if (msg->state() == MMSmsState::MM_SMS_STATE_RECEIVING) {
        connect(msg.get(), &ModemManager::Sms::dataChanged, this, [this, msg]() {
            if (msg->state() == MMSmsState::MM_SMS_STATE_RECEIVED) {
                if (!msg->data().isEmpty()) {
                    Q_EMIT messageAdded(msg);
                }
            }
        });
        connect(msg.get(), &ModemManager::Sms::textChanged, this, [this, msg]() {
            if (msg->state() == MMSmsState::MM_SMS_STATE_RECEIVED) {
                if (!msg->text().isEmpty()) {
                    Q_EMIT messageAdded(msg);
                }
            }
        });
    } else {
        Q_EMIT messageAdded(msg);
    }
}

void ModemController::deleteMessage(const QString &uni)
{
    for (const ModemManager::ModemMessaging::Ptr &mgr : std::as_const(m_msgManagers)) {
        if (mgr->findMessage(uni)) {
            mgr->deleteMessage(uni);
            return;
        }
    }

    if (!m_msgManager) {
        return;
    }

    m_msgManager->deleteMessage(uni);
}

ModemManager::Sms::List ModemController::messages()
{
    ModemManager::Sms::List list;
    for (int i = 0; i < m_msgManagers.size(); ++i) {
        const ModemManager::Sms::List part = m_msgManagers.at(i)->messages();
        for (const ModemManager::Sms::Ptr &sms : part) {
            m_uniDevice.insert(sms->uni(), m_msgDevices.value(i));
            if (sms->state() == MMSmsState::MM_SMS_STATE_RECEIVED) {
                rememberNumber(sms->number(), m_msgDevices.value(i));
            }
        }
        list += part;
    }
    if (m_msgManager && !m_msgManagers.contains(m_msgManager)) {
        list += m_msgManager->messages();
    }
    return list;
}

QString ModemController::ownNumber()
{
    if (!m_interface) {
        return QString();
    }

    const QStringList numbers = m_interface->ownNumbers();

    if (!numbers.isEmpty()) {
        if (numbers.startsWith(QStringLiteral("+"))) {
            return numbers.first();
        }
        return QStringLiteral("+") + numbers.first();
    }

    return QString();
}

QString ModemController::getDNS(QSharedPointer<ModemManager::Bearer> bearer)
{
    QStringList dnsServerList = {bearer->ip4Config().dns1(),
                                 bearer->ip4Config().dns2(),
                                 bearer->ip4Config().dns3(),
                                 bearer->ip6Config().dns1(),
                                 bearer->ip6Config().dns2(),
                                 bearer->ip6Config().dns3()};

    // remove empty items
    dnsServerList.removeAll(QString());

    return dnsServerList.join(QStringLiteral(","));
}
