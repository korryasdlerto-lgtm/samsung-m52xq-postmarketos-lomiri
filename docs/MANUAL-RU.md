# postmarketOS + Lomiri на mainline-ядре для Samsung Galaxy M52 5G (m52xq) — полная инструкция

Версия документа: 2026-11-02. Последний архив: **lomiri v5** (2026-10-30).

## 1. Что это

- Устройство: Samsung Galaxy M52 5G, SM-M526B / SM-M526BR, Snapdragon 778G (SM7325, платформа «yupik»), кодовое имя `m52xq`.
- Ядро: **mainline Linux 7.1.2**, сборка **#430** (boot v241 + vendor_boot v238) — то же ядро, что у Plasma-порта, без Halium и libhybris.
- Система: **postmarketOS edge** (Alpine), оболочка **Lomiri 0.6.2** (Ubuntu Touch), **без Plasma**. Набор — 1102 пакета (`docs/packages-003.txt`).
- Железо телефона (ядро, прошивки, службы `m52xq-*`) — общее с портом Plasma, репозиторий
  [samsung-m52xq-mainline](https://github.com/korryasdlerto-lgtm/samsung-m52xq-mainline). Здесь — то, что сделано для Lomiri поверх него.
- Личный любительский порт, проверен на одном SM-M526B.

Видео:
- установка: https://www.youtube.com/watch?v=7mkKoSjPERk
- возврат на Android: https://www.youtube.com/watch?v=0lgLbtdl4rA

## 2. Что работает

| Функция | Состояние | Примечание |
|---|---|---|
| Загрузка, оболочка Lomiri | работает | сеанс tinydm `m52xq-lomiri.desktop` → `/usr/local/bin/m52xq-start-lomiri`; заставка «postmarketOS / Lomiri» |
| Экран, GPU, касания | работает | Mir через gbm-kms и Mesa freedreno; панель S6E3HAB; Synaptics TCM |
| Экранная клавиатура | работает | maliit (Qt6), мост `m52xq-osk-bridge` для приложений text-input-v3 (Firefox) |
| Звонки | работает | plasma-dialer на 2 SIM с правками под Lomiri (поверх экрана блокировки, мелодия и вибрация `m52xq-ringtone`, журнал с номером SIM) |
| SMS | работает | Spacebar на нескольких модемах; непрочитанные — в индикаторе сообщений Lomiri (`m52xq-messaging-bridge`) |
| Мобильный интернет, две SIM | работает | ModemManager с патчами DSDS; SIM в шторке; меню выбора режима SIM |
| Wi-Fi, Bluetooth | работает | Wi-Fi остаётся включённым во сне и будит телефон пакетом (WoWLAN, свой `ath11k_ahb.ko`) |
| Звук | работает | динамик, разговорный, микрофоны; `m52xq-audio-reprobe` повторяет пробу VA-макро |
| Камера | работает | `lomiri-camera-app` с правками: видео через аппаратный Venus 1080p/4K (≤ 24 к/с), AAC, фокус по касанию, 16 Мп без шахматки |
| GPS | частично | ModemManager GNSS → gpsd → lomiri-location-service (`m52xq-gnss-gpsd`); в помещении фикса нет |
| Сон | работает | короткое нажатие питания — блокировка и гашение (`m52xq-powerkey`); пробуждение по звонку, SMS, Wi-Fi-пакету |
| Подкачка | работает | zram 7,4 ГБ (zstd) |
| Карты | работает | Pure Maps (osmscout-server, онлайн-профиль), Organic Maps |
| Отпечаток пальца | нет | |

Известные проблемы v5:
- камера держит Venus после остановки записи — родной плеер не открывает 4K, пока камера открыта;
- 4K с фронтальной ≈ 17 к/с;
- при пробуждении пакетом изредка ложно срабатывает «нажатие кнопки» и включается подсветка;
- «чужой» пинг без записи в ARP-кэше может не разбудить телефон (APF отбрасывает широковещательный ARP);
- `apk upgrade` заменит наши сборки (ModemManager, libcamera, plasma-dialer и др.) пакетами edge.

## 3. Что нужно

- SM-M526B с **разблокированным загрузчиком**;
- TWRP для m52xq: https://github.com/saadelasfur/Action-Recovery-Builder/releases/tag/20261004173308 ;
- карта microSD (Format Data стирает внутреннюю память);
- ПК с Odin и стоковой прошивкой под вашу модель — на случай возврата.

**Резервные копии сначала.** Из TWRP сохраните как минимум EFS, persist, modem, boot, vendor_boot, vbmeta и скопируйте на ПК.

Прошивки берутся с вашего телефона: установщик копирует прошивку модема, адрес Bluetooth (EFS) и реестр датчиков (persist) с самого
телефона (только чтение). Поэтому разделы `apnhlos`, `vendor`, `modem`, `persist`, `EFS` должны быть целыми, а `vendor` — от прошивки
на базе Samsung (сток, UN1CA или LineageOS).

## 4. Установка через TWRP

Архив: `postmarketos-lomiri-m52xq-mainline-v5.zip`, 1 570 774 902 байт, md5 `a7b6255ca8080f1251fd8b243fe26ab1`
(архив не публикуется в репозитории: в нём собранный образ системы; собирается по разделу 8).

Рекомендация по разделу system: установщик увеличивает раздел system до 8 000 000 000 байт. Максимальный размер раздела даёт
предварительная прошивка **UN1CA_3.1.0**; после LineageOS 23 раздел на 1 ГБ меньше, но установка тоже проходит.

Шаги в TWRP (как в видео):
```
Wipe - Format Data - yes - enter - Back - Back - Advanced Wipe - Data - Repair or Change File System - Change File System - EXT4 -
Swipe to Change - Back - Back - Back - Back - Back - Install - Select Storage - Micro SD card - UN1CA_3.1.0-a5bf09f2_20260604_m52xq-sign.zip -
Swipe to confirm Flash - Back - Back - Wipe - Format Data - enter - Back - Back - Advanced Wipe - Data - Repair or Change File System -
Change File System - EXT4 - Swipe to Change - Back - Back - Back - Back - Back - Install - postmarketos-lomiri-m52xq-mainline-v5.zip -
Swipe to confirm Flash - Reboot System
```
- Установка ≈ 2 минуты, в конце должно быть `Updater process ended with RC=0`.
- «Failed to mount /system_root» в конце — нормально для образа pmOS (TWRP ждёт Android).
- Если в корне `/data` лежит `rootfs.img`, загрузчик предпочтёт его — уберите или переименуйте перед установкой.

Что делает установщик (`installer/META-INF/com/google/android/update-binary`):
1. увеличивает раздел `system` (динамический раздел super) до 8 000 000 000 байт;
2. склеивает чанки `data/rootfs-chunks/samsung-m52xq.img.part-*` и пишет образ в `/dev/block/mapper/system`
   (GPT, сектор 4096, p1 `pmOS_boot`, p2 корень — первая загрузка растягивает p2 на весь раздел);
3. пишет `firmware/boot_v241_nfc.img` в `boot` и `firmware/vendor_boot_v238_nfc_se9.img` в `vendor_boot`;
4. кладёт файлы `mainline-extras/rootfs-files` поверх корня (это `rootfs-overlay/` этого репозитория), компилирует GSettings,
   восстанавливает включения служб (`*.wants`);
5. берёт с телефона: адрес Bluetooth из EFS, прошивку модема, реестр датчиков из persist (владелец — пользователь `fastrpc` образа).

**Пароль по умолчанию** (разблокировка и root): **112233** — ставит при первом запуске `m52xq-set-default-password`.
Сменить: в терминале `printf "user:НОВЫЙ\n" | sudo chpasswd`.

Доступ по USB: `ssh user@172.16.42.1` (сеть USB поднимает `m52xq-usbnet`).

## 5. Возврат на Android

Видео: https://www.youtube.com/watch?v=0lgLbtdl4rA
```
Wipe - Format Data - yes - enter - Back - Back - Back - Advanced Wipe - Data - Repair or Change File System - Change File System - EXT4 -
Swipe to Change - Back - Back - Back - Back - Back - Install - lineage-23.2-2026-nightly-m52xq-signed.zip - Back - Back - Wipe -
Format Data - enter - Reboot System
```
Стоковую прошивку всегда можно вернуть через Odin (BL, AP, CP, CSC).

## 6. Ядро

Готовые файлы — релиз [kernel-7.1.2-430](../../releases/tag/kernel-7.1.2-430) этого репозитория:

| Файл | Что это |
|---|---|
| `boot_v241_nfc.img` | загрузочный образ (ядро #430 + initramfs postmarketOS), md5 `f89bec954c6f3d4933503d260fce83a4` |
| `vendor_boot_v238_nfc_se9.img` | vendor_boot с DTB телефона (NFC, SE9), md5 `e1fb7dd3d01ad972f07887e0295e8fd7` |
| `Image` | ядро arm64 из boot v241 (DTB к ядру не дописан — он в vendor_boot) |
| `config-7.1.2-430` | полный `.config` сборки (clang 22 / LLD 22, `make ARCH=arm64 LLVM=1`) |
| `modules-7.1.2-430.tar.gz` | модули, раскладка `lib/modules/7.1.2/…`: `ath11k_ahb.ko` (вариант v5 с повтором выхода из сна), `extra/v4l2loopback.ko`, `extra/venus/*` |
| `SHA256SUMS` | контрольные суммы |

Почти все драйверы встроены в ядро; модулями только Wi-Fi AHB, v4l2loopback и Venus (их грузит `m52xq-venus-load` через insmod).
`MODVERSIONS` выключен — модули ставить только вместе с этим boot.

Прошить ядро отдельно (телефон в TWRP, файлы в `/data`):
```sh
adb push boot_v241_nfc.img vendor_boot_v238_nfc_se9.img /data/
adb shell 'dd if=/data/boot_v241_nfc.img of=/dev/block/by-name/boot bs=4M && dd if=/data/vendor_boot_v238_nfc_se9.img of=/dev/block/by-name/vendor_boot bs=4M && sync'
adb shell 'md5sum /dev/block/by-name/boot | head -c 32; echo'      # для сверки прочитать столько же байт, сколько в файле
```
Исходники ядра: [sc7280-mainline-linux-m52xq](https://github.com/korryasdlerto-lgtm/sc7280-mainline-linux-m52xq)
(ветка `master` — более новая #437; сборка #430 отличается от неё в основном отладкой). Свой ath11k для v5:
`build/v5/ath11k-ahb/ahb.c.m52xq-resume` (собирается вместо `drivers/net/wireless/ath/ath11k/ahb.c`).

## 7. Состав репозитория

| Папка | Что внутри |
|---|---|
| `installer/META-INF` | установщик TWRP (`update-binary`, `updater-script`), баннер «lomiri v5» |
| `rootfs-overlay/` | все файлы, наложенные поверх образа в версиях 2–5 (скрипты, службы, QML, конфиги); двоичные — в `rootfs-overlay/EXCLUDED-FILES.txt` с md5 |
| `image/` | сборка корня: `build-layer.sh`, список пакетов `world-003.txt`, репозитории, пакет устройства `device-pkg`, сеанс `extra-003`, заставка `splash` |
| `build/v2…v5/` | исходники и патчи каждой пересобранной программы по версиям (см. раздел 9) |
| `docs/` | эта инструкция (RU/EN), журнал `ЖУРНАЛ-УБУНТУТАЧ24.md`, все команды `КОМАНДЫ-УБУНТУТАЧ24.md`, списки дел по версиям, «Что нового v5» |

## 8. Сборка с нуля

Ниже — схема сборки с ключевыми командами. Точные команды, выполненные при сборке каждой версии (с выводом и md5), записаны
в `docs/КОМАНДЫ-УБУНТУТАЧ24.md` и `docs/ЖУРНАЛ-УБУНТУТАЧ24.md` (разделы «Этап 3» и «Архив lomiri vN»).

Хост: Ubuntu 20.04 x86_64, `qemu-user-static` + binfmt (флаг F), pmbootstrap (для `apk.static` и ключей), ≈ 20 ГБ места.

### 8.1. Корень postmarketOS edge + Lomiri
pmaports у pmbootstrap — ветка v26.06, `postmarketos-ui-lomiri` есть только в edge, поэтому корень ставится `apk.static` напрямую
с репозиториями телефона (`image/repositories`) и отдельным кэшем:
```sh
R=$PWD/rootfs; mkdir -p $R/etc/apk; cp image/repositories $R/etc/apk/repositories
sudo cp -a ~/.local/var/pmbootstrap/config_apk_keys $R/etc/apk/keys
sudo ~/.local/var/pmbootstrap/apk.static --arch aarch64 --root $R --initdb --cache-dir $PWD/apk-cache \
     --allow-untrusted add $(grep -v '^#' image/world-003.txt)
```
Состав (`world-003.txt`, 70 имён → 1102 пакета): база как у телефона (`postmarketos-base`, `-systemd`, `postmarketos-mkinitfs`, sudo-rs),
`postmarketos-ui-lomiri`, `lomiri-ui-extras-qt5`, `maliit-keyboard`, индикаторы ayatana, ModemManager, rmtfs, tqftpserv, hexagonrpcd,
qrtr, libssc, iio-sensor-proxy, `postmarketos-usb-moded`, Megapixels, Firefox, Organic Maps, приложения Lomiri.
`telegram-desktop` не вошёл (edge 7.3.3 требует отсутствующую `libada.so.3`; своя сборка ada — `build/v3/ada3/APKBUILD`).

### 8.2. Слой железа m52xq
`image/build-layer.sh` (воспроизводимый) накладывает по порядку:
1. оверлей Plasma-порта (`samsung-m52xq-mainline/rootfs-overlay`, состояние v42) без Plasma/KDE;
2. слой, снятый с телефона только чтением (прошивки, `/etc/m52xq`, реестр датчиков, `/usr/local`, udev, NM/ssh/polkit, юниты `m52xq-*`) —
   **в репозиторий не входит**, это личные данные телефона: установщик создаёт их сам на вашем телефоне;
3. исправления Lomiri: заглушки LightDM.IntegratedLightDM и SystemSettings.Update, обёртки `lomiri-bin`, maliit на wayland, deviceinfo (GridUnit 21);
4. `image/extra-003`: сеанс tinydm, свой `fstab` (журналы, coredump, кэш apk — на userdata; домашний каталог в образе), портрет по умолчанию;
5. модули ядра #430 (`modules-7.1.2-430.tar.gz` из релиза) и пакет устройства `image/device-pkg`.

Отличия свежего edge, учтённые вручную: `/lib`, `/sbin` — настоящие каталоги (прошивки в `/lib/firmware`, ссылки из `/usr/lib/firmware`);
`fastrpc` = 103:105 (реестр датчиков переназначается установщиком); пользователь `user` 10000:10000, группы wheel audio input video
netdev plugdev feedbackd; права каталогов восстановлены по базе apk; выключены `hexagonrpcd-sdsp` и `routewrangler`.

### 8.3. Правки версий 2–5
Наложить `rootfs-overlay/` поверх корня (владелец root, права как в оверлее):
```sh
sudo cp -a --no-preserve=ownership rootfs-overlay/. $R/
sudo chroot $R glib-compile-schemas /usr/share/glib-2.0/schemas
```
Двоичные файлы из `EXCLUDED-FILES.txt` собираются из `build/` (раздел 9) или берутся из релиза (модули).

### 8.4. Образ и архив
```sh
# образ GPT, сектор 4096: p1 pmOS_boot (из Plasma-архива в35), p2 корень (тип B921B045, метка pmOS_root)
truncate -s 5338300416 samsung-m52xq.img
L=$(sudo losetup -f --show -P --sector-size 4096 samsung-m52xq.img)    # разметку делать на loop с сектором 4096, не на файле
sudo sgdisk -o -n1:2048:124927 -c1:pmOS_boot -n2:124928:0 -t2:B921B045-1DF0-41C3-AF44-4C6F280D3FAE -c2:pmOS_root $L
sudo partprobe $L
sudo dd if=pmOS_boot.img of=${L}p1 bs=4M; sudo mkfs.ext4 -L pmOS_root -b 4096 ${L}p2
sudo mount ${L}p2 /mnt && sudo cp -a $R/. /mnt/ && sudo umount /mnt && sudo e2fsck -fy ${L}p2 && sudo losetup -d $L
# архив: чанки + установщик + ядро + оверлей
mkdir -p archive/data/rootfs-chunks archive/firmware archive/mainline-extras/rootfs-files
split -b 2669150208 -d -a 1 samsung-m52xq.img archive/data/rootfs-chunks/samsung-m52xq.img.part-
cp -a installer/META-INF archive/; cp boot_v241_nfc.img vendor_boot_v238_nfc_se9.img archive/firmware/
cp -a rootfs-overlay/. archive/mainline-extras/rootfs-files/; rm archive/mainline-extras/rootfs-files/EXCLUDED-FILES.txt
find archive -xtype l                                     # битых ссылок быть не должно
cd archive && zip -9 -r ../postmarketos-lomiri-m52xq-mainline-vN.zip . && cd ..   # изнутри папки, без префикса
unzip -t postmarketos-lomiri-m52xq-mainline-vN.zip | tail -1
```
Перед упаковкой снятого с телефона корня удалить личные данные: `etc/m52xq/{bt_addr,data-sim,sim-mode}`, `lib/firmware/modem*`,
реестр датчиков `usr/share/qcom/…/sensors/registry/*`, Wi-Fi `*.nmconnection` (кроме `m52xq-mobile-internet`), `var/lib/bluetooth/*`,
`etc/ssh/ssh_host_*`, `etc/machine-id` (оставить пустым), историю, кэши, журналы (`build/v3/clean-image-v3.sh`).

## 9. Пересобранные программы (`build/`)

| Папка | Что изменено |
|---|---|
| `v2/maliit-qt6` | maliit-framework под Qt6 (CMake из ветки master и PR 125) |
| `v3/integratedlightdm` | заглушка LightDM для Lomiri без lightdm (патчи 0001–0006, APKBUILD) |
| `v3/lomiri-app-launch` | `0002-m52xq-posix-reap-children-per-app-pids-stop` — завершение процессов приложения |
| `v3/lomiri-launcher`, `v3/lomiri-shell` | индекс ярлыка в момент нажатия; два обоя (рабочий стол / блокировка) |
| `v3/lomiri-system-settings` | «О телефоне» под mainline (IMEI из ModemManager, ОС, лицензии apk), яркость, перевод ru |
| `v3/lomiri-camera-app`, `v5/lomiri-camera-app` | QZXing необязателен, видео 4K, 16 Мп с биннингом |
| `v3/m52xqcamsrc`, `v5/m52xqcamsrc` | свой GStreamer-источник камеры с аппаратным кодированием Venus и автофокусом |
| `v3/libcamera` | APKBUILD + патчи soft-ISP (ремозаика tetracell S5KGW3, без записи в сенсор без AGC) |
| `v3/plasma-dialer`, `v4/dialer-*`, `v4/incoming-call` | 2 SIM, звонок поверх блокировки, без полноэкранного режима, «добавить контакт», SIM в журнале, решение о звонке в Lomiri |
| `v4/spacebar-multimodem` | SMS на нескольких модемах |
| `v4/calls-lockedapp` | Shell.qml: звонилка поверх экрана блокировки |
| `v3/powerkey` | `m52xq-powerkey` v2: бездействие, «не выключать экран», сон |
| `v3/qmlkonsole` | панель клавиш над экранной клавиатурой |
| `v3/aa-shim`, `v3/cellular`, `v3/indicator-bluetooth` | заглушка AppArmor для click, модуль сотовой связи настроек, индикатор Bluetooth |
| `v3/translations` | русские переводы настроек и индикатора питания |
| `v5/ath11k-ahb` | `ahb.c` с повтором выхода из сна (WoWLAN) |

Сборка — в chroot pmbootstrap (aarch64) или Alpine-chroot; точные команды каждой сборки — в `docs/КОМАНДЫ-УБУНТУТАЧ24.md` и `docs/ЖУРНАЛ-УБУНТУТАЧ24.md`.

## 10. Службы и скрипты Lomiri-слоя

| Служба / скрипт | Назначение |
|---|---|
| `m52xq-start-lomiri` | запуск сеанса Lomiri (PATH с lomiri-bin, QML2_IMPORT_PATH, GRID_UNIT_PX=21) |
| `m52xq-powerkey` (+ .service) | короткое нажатие питания: блокировка и гашение / включение экрана, сон |
| `m52xq-osk-bridge` | экранная клавиатура для text-input-v3 (Firefox): input_method_v2 ↔ maliit-server |
| `m52xq-ringtone` | мелодия и вибрация входящего звонка модема |
| `m52xq-incall-proximity` | гашение экрана у уха во время звонка |
| `m52xq-messaging-bridge` | непрочитанные SMS в индикаторе сообщений Lomiri |
| `m52xq-sim-slots`, `m52xq-indicator-sim`, `m52xq-sim-mode-menu` | номер слота каждой SIM (ICCID), SIM в шторке, меню режима SIM |
| `m52xq-gnss-gpsd` | GNSS ModemManager (NMEA) → gpsd для lomiri-location-service |
| `m52xq-wow-params`, `m52xq-wifi-*`, `m52xq-timesyncd.sh` | флаги WoW, Wi-Fi во сне, синхронизация времени после сна |
| `m52xq-audio-reprobe` | повтор пробы VA-макро LPASS после гонки старта ADSP |
| `m52xq-reboot-recovery` | меню питания: перезагрузка в recovery |
| `m52xq-app-env` | окружение запуска приложений (масштаб, переменные Qt) |
| `m52xq-camera-postprocess` | обработка снимков камеры |

Общие службы железа (модем, звук, датчики, Wi-Fi, сон, NFC) — в репозитории Plasma-порта.

## 11. Ловушки

- Lomiri-телефония (`lomiri-telephony-service`) требует telepathy-ofono, у нас модем через ModemManager — поэтому звонки и SMS сделаны plasma-dialer и Spacebar.
- `iio-sensor-proxy` поворачивал окна приложений → касания попадали мимо; в 003 он замаскирован, ориентация — портрет.
- Не ставить на телефон dev-пакеты, которые понижают systemd/libc; `apk upgrade` заменяет наши сборки.
- `pkill -f` в ssh-команде убивает свою же сессию — завершать по PID.
- zip собирать только изнутри папки архива (`cd archive && zip -9 -r ../x.zip .`), иначе TWRP не найдёт `META-INF`.
- `losetup` образа — обязательно `--sector-size 4096`, иначе разделы p1/p2 не видны.

## 12. Благодарности
postmarketOS и pmbootstrap; UBports и Lomiri; KDE (plasma-dialer, Spacebar); разработчикам mainline Linux для Qualcomm SC7280/QCM6490.
