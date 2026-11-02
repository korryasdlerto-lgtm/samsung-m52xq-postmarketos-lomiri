// Заглушка LightDM.IntegratedLightDM: данные круга на экране блокировки (в Ubuntu Touch их даёт lomiri-libusermetrics).
// v2 (убунтутач24/003): фото по дням — файлы в ~/Pictures (Megapixels, снимки экрана в Pictures/Screenshots):
// как на экране Ubuntu Touch: точки по дням месяца, один оранжевый круг — сегодня (размер по числу фото), по центру
// «Сегодня сделано N фото»; без внешнего кольца прошлого месяца (по просьбе пользователя).
// nextDataSource()/readyForDataChange() переключают фото и снимки экрана.
pragma Singleton
import QtQuick 2.15
import Qt.labs.folderlistmodel 2.15

QtObject {
    id: info

    property string username: "user"
    property string label: ""
    property var firstMonth: []
    property var secondMonth: []
    property int currentDay: new Date().getDate() - 1

    property int source: 0	// 0 photos, 1 screenshots
    property int nextSource: 0
    readonly property bool russian: Qt.locale().name.indexOf("ru") === 0

    property FolderListModel photos: FolderListModel {
        folder: "file:///home/user/Pictures"
        nameFilters: ["*.jpg", "*.jpeg", "*.png", "*.dng", "*.JPG"]
        showDirs: false
        onStatusChanged: if (status === FolderListModel.Ready) info.rebuild()
        onCountChanged: info.rebuild()
    }
    property FolderListModel screenshots: FolderListModel {
        folder: "file:///home/user/Pictures/Screenshots"
        nameFilters: ["*.png", "*.jpg"]
        showDirs: false
        onStatusChanged: if (status === FolderListModel.Ready) info.rebuild()
        onCountChanged: info.rebuild()
    }

    function scale(n) { return n > 0 ? Math.min(1.0, 0.3 + 0.12 * n) : 0.12; }

    function rebuild() {
        var m = source === 0 ? photos : screenshots;
        var now = new Date();
        var y = now.getFullYear(), mo = now.getMonth(), today = now.getDate();
        var daysNow = new Date(y, mo + 1, 0).getDate();
        var daysPrev = new Date(y, mo, 0).getDate();
        var cur = [], prev = [], i;
        for (i = 0; i < daysNow; i++) cur.push(0);
        for (i = 0; i < daysPrev; i++) prev.push(0);
        for (i = 0; i < m.count; i++) {
            var t = m.get(i, "fileModified");
            if (!t) continue;
            if (t.getFullYear() === y && t.getMonth() === mo)
                cur[t.getDate() - 1]++;
            else if ((t.getFullYear() === y && t.getMonth() === mo - 1) || (mo === 0 && t.getFullYear() === y - 1 && t.getMonth() === 11))
                prev[t.getDate() - 1]++;
        }
        var n = cur[today - 1];
        var f = [], s = [];
        // only today: one circle (the rest of the month and the previous month stay without circles). The previous
        // month still needs its entries (undefined = no circle): Infographics.qml animates the present circles only after
        // it has gone through half of the past ones, so with an empty array today's circle never appeared
        for (i = 0; i < daysNow; i++) f.push(i === today - 1 ? 1.0 : undefined);	// today: the full size (the photo count is in the label)
        for (i = 0; i < daysPrev; i++) s.push(undefined);
        currentDay = today - 1;
        firstMonth = f;
        secondMonth = s;
        if (source === 0)
            label = n > 0 ? (russian ? "Сегодня сделано фото: " + n : n + " photos taken today")
                          : (russian ? "Сегодня нет фотографий" : "No photos taken today");
        else
            label = n > 0 ? (russian ? "Снимков экрана сегодня: " + n : n + " screenshots today")
                          : (russian ? "Сегодня нет снимков экрана" : "No screenshots today");
    }

    function nextDataSource() { nextSource = (source + 1) % 2; }
    function readyForDataChange() {
        if (nextSource !== source) {
            source = nextSource;
            rebuild();
        }
    }

    Component.onCompleted: rebuild()
}
