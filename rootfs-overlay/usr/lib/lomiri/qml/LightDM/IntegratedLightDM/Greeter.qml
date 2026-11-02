// Заглушка LightDM.IntegratedLightDM для postmarketOS (в Alpine-сборке lomiri нет нативного плагина).
// Пароля на телефоне нет. v2 (убунтутач24/003): экран блокировки с часами и кругом. authenticate() кладёт один запрос
// типа «кнопка» (Button = 3, вход без пароля) и не шлёт loginSuccess сам: Lomiri показывает обложку, свайп вызывает
// respond → Greeter.qml d.login() → startSessionSync(), и экран снимается. Раньше loginSuccess уходил сразу (режим
// full-shell), блокировки не было; без запросов вовсе Greeter ждал (waiting: prompts.count == 0) — белая шторка на 002.
pragma Singleton
import QtQuick 2.15
import LightDM.IntegratedLightDM 0.1 as LightDM

QtObject {
    id: greeter

    property bool active: false
    property bool authenticated: true
    property string authenticationUser: ""
    property string defaultSession: "lomiri"
    property string selectUser: ""
    property bool promptless: true
    property bool hasGuestAccount: false

    signal showGreeter()
    signal hideGreeter()
    signal loginError(bool automatic)
    signal loginSuccess(bool automatic)
    signal requestAuthenticationUser(string user)

    function authenticate(user) {
        authenticationUser = user;
        authenticated = true;
        LightDM.Prompts.clear();
        LightDM.Prompts.append({ "text": "", "type": 3 });	// Button: unlock without a password
        console.log("m52xq-lightdm: authenticate", user, "prompts", LightDM.Prompts.count);
    }
    function respond(response) { greeter.loginSuccess(false); }
    function startSessionSync(session) { return true; }
    function hideSessionChooser() {}
    function showGuestAccount() {}
}
