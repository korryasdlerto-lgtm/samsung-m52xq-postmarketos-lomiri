/*
 * Copyright 2014 Canonical Ltd.
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

import QtQuick 2.12
import Lomiri.Components 1.3
import Lomiri.Components.Popups 1.3

Dialog {
    signal deleteFiles()

    title: i18n.tr("Delete media?")

    Component.onCompleted: {
        deleteButton.clicked.connect(deleteFiles);
    }

    Button {
        id: deleteButton
        objectName: "deleteButton"

        text: i18n.tr("Delete")
        color: theme.palette.normal.negative
        onClicked: PopupUtils.close(deleteDialog)
    }

    Button {
        text: i18n.tr("Cancel")
        onClicked: PopupUtils.close(deleteDialog)
    }
}

