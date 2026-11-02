import QtQuick 2.12
import Lomiri.Components 1.3
import Lomiri.Components.Popups 1.3

import CameraApp 0.1

Popover {
    id: infoPopover
    property var currentMedia: null
    property var model: null
    property var exifData: currentMedia != undefined ? fileOperations.getEXIFData(currentMedia.url) : undefined

    property var infoKeys : [
              { "key": 'Exif.Photo.PixelYDimension' , "title" : i18n.tr( "Width : %1")},
              { "key": 'Exif.Photo.PixelXDimension' , "title" :i18n.tr( "Height : %1")},
              { "key": 'Exif.Photo.DateTimeOriginal' , "title" :i18n.tr( "Date : %1")},
              { "key": 'Exif.Image.Model' , "title" :i18n.tr( "Camera Model : %1")},
              { "key": 'Exif.Image.Copyright' , "title" :i18n.tr( "Copyright : %1")},
              { "key": 'Exif.Image.ExposureTime' , "title" :i18n.tr( "Exposure Time : %1")},
              { "key": 'Exif.Image.FNumber' , "title" :i18n.tr( "F. Number : %1")},
              { "key": 'Exif.Image.NewSubfileType' , "title" :i18n.tr( "Sub-File type : %1")},
            ];

    FileOperations {
        id: fileOperations
    }

    autoClose: true

    Item {
        height: childrenRect.height + units.gu(4)
        anchors {
            centerIn: parent
            margins: units.gu(1)
        }
        Column {
            anchors {
                centerIn: parent
            }

            spacing:units.gu(1)
            Label {
                text:i18n.tr("Media Information");
                textSize: Label.Large
                color: theme.palette.normal.overlayText
            }
            Label {
                text:i18n.tr("Name : %1".arg(infoPopover.model.fileName))
            }
            Label {
                text:i18n.tr("Type : %1").arg(infoPopover.model.fileType)
            }
            //Print stright forward EXIF data
            Repeater {
                model:infoKeys
                Label {
                    visible: undefined !== exifData && undefined !== exifData[modelData['key']];
                    text:visible ? modelData["title"].arg(exifData[modelData['key']]) : "";
                }
            }
            Label {
                visible: undefined !== exifData && undefined !== exifData['Exif.Photo.Flash'];
                text: {
                    if (!visible)
                        return "";

                    var flashTag = parseInt(exifData['Exif.Photo.Flash'], /* radix */ 10);

                    /*
                     * From https://www.awaresystems.be/imaging/tiff/tifftags/privateifd/exif/flash.html:
                     *
                     * Exif TIFF Tag Flash, code 37385 (0x9209)
                     *
                     * Indicates the status of flash when the image was shot.
                     *
                     * Bit 0 indicates the flash firing status, bits 1 and 2
                     * indicate the flash return status, bits 3 and 4 indicate
                     * the flash mode, bit 5 indicates whether the flash
                     * function is present, and bit 6 indicates "red eye" mode.
                     */
                    var flashDidFire = (flashTag & (1 << 0));

                    return i18n.tr("With Flash : %1").arg( flashDidFire ? i18n.tr("Yes") : i18n.tr("No"));
                }
            }
        }
    }

    }
