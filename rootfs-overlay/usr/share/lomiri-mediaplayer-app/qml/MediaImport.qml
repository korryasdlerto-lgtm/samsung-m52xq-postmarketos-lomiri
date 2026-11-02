/*
 * Copyright (C) 2012-2016 Canonical, Ltd.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.4

import Lomiri.Components 1.3
import Lomiri.Components.Popups 1.3

Item {
    id: root

    property var importDialog: null

    signal mediaReceived(string url)

    function requestMedia()
    {
        if (!root.importDialog) {
            root.importDialog = PopupUtils.open(Qt.resolvedUrl("MediaImportDialog.qml"), null)
            root.importDialog.mediaReceived.connect(root.mediaReceived)
            root.importDialog.destruction.connect(function () {root.importDialog = null})

        } else {
            console.warn("Import dialog already running")
        }
    }
}
