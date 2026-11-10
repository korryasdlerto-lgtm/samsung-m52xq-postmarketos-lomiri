# postmarketOS + Lomiri на mainline-ядре для Samsung Galaxy M52 5G (m52xq) — полная инструкция

Версия документа: 2026-11-10. Релиз: **unofficial v1** (2026-11-10), архив `postmarketos-lomiri-m52xq-mainline-v1-UNOFFICIAL.zip`.
Что изменилось после архива v5 — [CHANGES-v1-RU.md](CHANGES-v1-RU.md).

## 1. Что это

- Устройство: Samsung Galaxy M52 5G, SM-M526B / SM-M526BR, Snapdragon 778G (SM7325, платформа «yupik»), кодовое имя `m52xq`.
- Ядро: **mainline Linux 7.1.13** с правками устройства — то же ядро, что у порта Ubuntu Lomiri (classic), без Halium и libhybris.
  Все драйверы родные для Linux (DRM/KMS, ALSA, модем по QMI).
- Система: **postmarketOS edge** (Alpine, systemd), оболочка **Lomiri 0.6.2** (Ubuntu Touch), **без Plasma**. Список пакетов базы — `docs/packages-003.txt`.
- Железо телефона (прошивки, службы `m52xq-*`) — общее с портом Plasma, репозиторий
  [samsung-m52xq-mainline](https://github.com/korryasdlerto-lgtm/samsung-m52xq-mainline). Здесь — то, что сделано для Lomiri поверх него.
- Неофициальный порт: не релиз postmarketOS или UBports. Личный любительский проект, проверен на одном SM-M526B.
- Страница на вики: [User:Asdlerto Korry](https://wiki.nura.eco/wiki/User:Asdlerto_Korry)

Видео:
- установка: https://www.youtube.com/watch?v=7mkKoSjPERk
- возврат на Android: https://www.youtube.com/watch?v=0lgLbtdl4rA

## 2. Что работает

| Функция | Состояние | Примечание |
|---|---|---|
| Загрузка, оболочка Lomiri | работает | загрузка с UFS, раздел system 8 ГБ; сеанс tinydm `m52xq-lomiri.desktop` → `m52xq-start-lomiri`; заставка «postmarketOS / Lomiri» |
| Мастер первого запуска | работает | язык, Wi-Fi, часовой пояс (выбранный пояс применяется: правило polkit для systemd-timedated) |
| Экран, GPU, касания | работает | Mir через gbm-kms и Mesa freedreno (Adreno 642L); панель S6E3HAB, яркость, автоповорот; Synaptics; быстрые нажатия на номеронабирателе не теряются |
| Экранная клавиатура | работает | maliit (Qt6), мост `m52xq-osk-bridge` для приложений text-input-v3 (Firefox) |
| Звонки | работает | plasma-dialer на 2 SIM с правками под Lomiri: окно звонка поверх экрана блокировки, полоска звонка со временем и именем, переключение громкая/разговорный в звонке |
| Звонки во сне | работает | экран включается на звонок модема; после звонка возвращается экран блокировки (звонилка больше не «залипает») |
| SMS | работает | Spacebar на нескольких модемах; непрочитанные — в индикаторе сообщений Lomiri (`m52xq-messaging-bridge`) |
| Две SIM, мобильный интернет | работает | ModemManager с патчами DSDS; менеджер SIM: питание SIM, режим (две / только SIM1 / только SIM2), SIM данных и переключатель данных, синхронный со шторкой |
| Контакты | работает | имена в звонилке и журнале |
| Wi-Fi, Bluetooth | работает | WCN6750; Wi-Fi остаётся подключённым во сне и будит телефон входящим пакетом (WoWLAN + APF); звук по Bluetooth |
| Telegram Desktop | работает | сообщения и звонки приходят во сне, экран включается на звонок, звук разговора в разговорном динамике |
| Звук | работает | динамик, разговорный, микрофоны, шумоподавление в звонке |
| Камера | работает | `lomiri-camera-app` со своим источником GStreamer: задняя и фронтальная, цифровой зум до 4x, видео через аппаратный Venus; Megapixels под Lomiri |
| GPS | работает | ModemManager GNSS → gpsd → lomiri-location-service; данные XTRA для быстрого фикса; Pure Maps |
| Датчики | работает | освещённость, приближение (гашение экрана у уха), акселерометр |
| Батарея, зарядка | работает | уровень заряда, быстрая зарядка Samsung AFC 9 В |
| Сон | работает | около 1 % в час за ночь с подключённым Wi-Fi; пробуждение по звонку, SMS, будильнику; при пробуждениях по сети экран не вспыхивает |
| Будильник | работает | будит телефон из сна (RTC) |
| Подкачка | работает | zram (zstd) |
| Отпечаток пальца, VoLTE | нет | звонки идут по 2G/3G |

Известные проблемы v1:
- изредка прошивка Wi-Fi падает в долгом сне, и Wi-Fi остаётся выключенным — возвращает перезагрузка;
- после смены сети значок Wi-Fi в верхней панели может пропасть при подключённом Wi-Fi — помогает перезагрузка;
- окно «Настройки → Время и дата», открытое до смены часового пояса, показывает старое время — закройте и откройте снова;
- не все объективы и режимы камеры поддержаны; обработка снимка — программная;
- `apk upgrade` заменит пропатченные пакеты порта (ModemManager, plasma-dialer, Kirigami и др.) пакетами edge — полное обновление не запускайте.

## 3. Что нужно

- SM-M526B с **разблокированным загрузчиком**;
- TWRP для m52xq: https://github.com/saadelasfur/Action-Recovery-Builder/releases/tag/20261004173308 ;
- карта microSD с архивами (Format Data стирает внутреннюю память);
- ПК с Odin и стоковой прошивкой под вашу модель и регион — на случай возврата.

**Резервные копии сначала.** Из TWRP сохраните как минимум EFS, persist, modem, boot, vendor_boot, vbmeta и скопируйте на ПК.

**Прошивки берутся с вашего телефона.** В архиве нет закрытых прошивок: установщик копирует прошивки DSP, GPU, IPA (мобильные данные),
видеокодека, Bluetooth, модема и конфиги датчиков с разделов самого телефона `apnhlos`, `vendor`, `modem`, `persist`, `EFS`
(только чтение). Поэтому эти разделы должны быть целыми, а `vendor` — от прошивки на базе Samsung (сток, UN1CA или LineageOS).
Свои адрес Bluetooth, ключи SSH и machine-id телефон тоже получает при установке и первом запуске.

## 4. Установка через TWRP

Архив: `postmarketos-lomiri-m52xq-mainline-v1-UNOFFICIAL.zip`, 1 411 797 780 байт (1,3 ГБ), md5 `eba0bbd593c733a6f49ccc6ab4d63ac2`.
Скачать: https://drive.google.com/file/d/1oQfJQ7r_41BDXRptXBHdAxwSDonf08J7/view?usp=sharing
(в репозиторий архив не входит: в нём собранный образ системы; как он собирается — раздел 8).

**Внимание:** телефон греется во время установки. Если на экране уже есть вертикальные цветные полосы, не устанавливайте: нагрев
может их усилить.

Рекомендация по разделу system: установщик увеличивает раздел system до 8 000 000 000 байт, и система занимает его целиком.
Максимальный размер раздела даёт предварительная прошивка **UN1CA_3.1.0**; после LineageOS 23 раздел на 1 ГБ меньше, но установка тоже проходит.

Шаги в TWRP (как в видео):
```
Wipe - Format Data - yes - enter - Back - Back - Advanced Wipe - Data - Repair or Change File System - Change File System - EXT4 -
Swipe to Change - Back - Back - Back - Back - Back - Install - Select Storage - Micro SD card -
postmarketos-lomiri-m52xq-mainline-v1-UNOFFICIAL.zip - Swipe to confirm Flash - Reboot System
```
- С v5 и более старых архивов нужна такая же чистая установка (Format Data).
- Установка ≈ 2 минуты, в конце должно быть `Updater process ended with RC=0`.
- «Failed to mount '/system_root'» в самом конце — нормально для образа pmOS (TWRP ждёт Android).
- Первая загрузка дольше обычной, затем запускается мастер: язык, Wi-Fi, часовой пояс.
- Если в корне `/data` лежит `rootfs.img`, загрузчик предпочтёт его — уберите или переименуйте перед установкой.

Что делает установщик (`installer/META-INF/com/google/android/update-binary`):
1. пишет `firmware/boot_v256_k7.1.13_panel-sleep.img` в `boot`, перед этим дописывает в его ramdisk прошивку IPA с раздела `apnhlos`
   телефона (IPA встроен в ядро и стартует до монтирования корня);
2. пишет `firmware/vendor_boot_m52xq-local-v35-rtc.img` в `vendor_boot` и `firmware/dtbo-frag-m52xq.img` в `dtbo`;
3. увеличивает раздел `system` (динамический раздел super) до 8 000 000 000 байт;
4. склеивает чанки `data/rootfs-chunks/samsung-m52xq.img.part-*` и пишет образ в `/dev/block/mapper/system`
   (GPT, сектор 4096, p1 `pmOS_boot`, p2 корень — первая загрузка растягивает p2 на весь раздел);
5. кладёт файлы `mainline-extras/rootfs-files` поверх корня (в v1 это правило polkit часового пояса и метка
   `/etc/m52xq/lomiri-release`), компилирует GSettings;
6. берёт с телефона (только чтение): адрес Bluetooth из EFS; прошивки ADSP, GPU, IPA, Venus с `apnhlos`; прошивку Bluetooth и
   конфиги датчиков с `vendor`; прошивку модема с `modem`; реестр датчиков из `persist`.

Раздел `userdata` установщик не трогает.

**Пароль по умолчанию** (4-значная разблокировка экрана, пользователь `user` и root): **1111**.
Сменить: «Настройки → Безопасность и конфиденциальность» или в терминале `printf "user:НОВЫЙ\n" | sudo chpasswd`.

Доступ по USB (через ≈ 30 с после загрузки): `ssh user@172.16.42.1`, пароль 1111 (сеть USB поднимает `m52xq-usbnet`).

Снимок экрана: **громкость вверх + громкость вниз** одновременно; файл — в `~/Pictures/Screenshots`.

## 5. Возврат на Android

Видео: https://www.youtube.com/watch?v=0lgLbtdl4rA

Подходит для возврата на LineageOS или UN1CA; сток лучше возвращать через Odin или Heimdall. Если в порту, с которого
возвращаетесь, нет перезагрузки в recovery, войдите в него обычным сочетанием кнопок питания и громкости. Архив прошивки заранее
скопируйте на microSD.
```
Wipe - Format Data - yes - enter - Back - Back - Back - Advanced Wipe - Data - Repair or Change File System - Change File System - EXT4 -
Swipe to Change - Back - Back - Back - Back - Back - Install - lineage-23.2-2026-nightly-m52xq-signed.zip - Back - Back - Wipe -
Format Data - enter - Reboot System
```
Свежая сборка LineageOS: https://download.lineageos.org/devices/m52xq/builds .
Стоковую прошивку всегда можно вернуть через Odin (BL, AP, CP, CSC).

## 6. Ядро

Подробно — [kernel/README.md](../kernel/README.md): `kernel/config-7.1.13` и правки `kernel/patches/*.diff`
(переключение устройства звонка без новых голосовых сессий q6voice, сон панели при яркости 0, энергосбережение ath11k при выключенном радио).

Готовые файлы (`boot.img`, `vendor_boot.img`, `dtbo-frag.img`, `Image`, `modules-7.1.13.tar.gz`, `SHA256SUMS`) — релиз
[kernel-7.1.13](https://github.com/korryasdlerto-lgtm/samsung-m52xq-ubuntu-lomiri/releases/tag/kernel-7.1.13) репозитория
samsung-m52xq-ubuntu-lomiri. Образы в `firmware/` архива v1 побайтно совпадают с `boot.img`, `vendor_boot.img`, `dtbo-frag.img`
этого релиза (sha256 `2b5962c1…`, `53965b55…`, `c9114568…`).

Дерево устройств — в стиле апстрима с локальными узлами, включён RTC (будильник из сна). Почти все драйверы встроены в ядро;
модулями — Wi-Fi AHB, v4l2loopback и Venus. `MODVERSIONS` выключен — модули ставить только вместе с этим boot.

Прошить ядро отдельно (телефон в TWRP, файлы в `/data`):
```sh
adb push boot.img vendor_boot.img dtbo-frag.img /data/
adb shell 'dd if=/data/boot.img of=/dev/block/by-name/boot bs=4M && dd if=/data/vendor_boot.img of=/dev/block/by-name/vendor_boot bs=4M && dd if=/data/dtbo-frag.img of=/dev/block/by-name/dtbo bs=4M && sync'
adb shell 'md5sum /dev/block/by-name/boot | head -c 32; echo'      # для сверки прочитать столько же байт, сколько в файле
```
Без установщика в boot не попадёт прошивка IPA, и мобильные данные не заработают — прошивайте ядро отдельно, только если понимаете это.

Исходники ядра: [sc7280-mainline-linux-m52xq](https://github.com/korryasdlerto-lgtm/sc7280-mainline-linux-m52xq).
Старое ядро архивов v2–v5: `kernel/config-7.1.2-430` и релиз kernel-7.1.2-430 этого репозитория.

## 7. Состав репозитория

| Папка | Что внутри |
|---|---|
| `installer/META-INF` | установщик TWRP (`update-binary`, `updater-script`) релиза v1 |
| `rootfs-overlay/` | все файлы, наложенные поверх образа в версиях 2 – v1 (скрипты, службы, хуки сна, QML, конфиги); двоичные — в `rootfs-overlay/EXCLUDED-FILES.txt` (путь, размер, md5) |
| `image/` | сборка корня: `build-layer.sh`, списки пакетов, репозитории, пакет устройства `device-pkg`, сеанс `extra-003`, заставка `splash`; `build-v6/v7/v8-image.sh` — снимок образа релиза |
| `build/v2…v7/` | исходники и патчи каждой пересобранной программы по версиям (раздел 9) |
| `kernel/` | конфиги и правки ядра |
| `docs/` | эта инструкция (RU/EN, Markdown и Word), CHANGES-v1, журнал `ЖУРНАЛ-УБУНТУТАЧ24.md`, все команды `КОМАНДЫ-УБУНТУТАЧ24.md`, «Что нового» v5–v9, списки дел |

Личные данные тестового телефона (адрес Bluetooth, реестр датчиков, сети Wi-Fi, данные SIM, ключи, координаты) в репозиторий не входят.

## 8. Сборка

Точные команды, выполненные при сборке каждой версии (с выводом и md5), — в `docs/КОМАНДЫ-УБУНТУТАЧ24.md` и
`docs/ЖУРНАЛ-УБУНТУТАЧ24.md`; что изменено в каждой версии — `docs/ЧТО_НОВОГО-v5.txt` … `-v9.txt`.

Хост: Ubuntu 20.04 x86_64, `qemu-user-static` + binfmt (флаг F), pmbootstrap (для `apk.static` и ключей), ≈ 20 ГБ места.

Образ v1 получен в два этапа: базовый корень (8.1–8.3, архивы v2–v5), затем на телефоне поставлены и проверены правки v6–v8,
и с настроенного телефона снят чистый снимок (8.4).

### 8.1. Корень postmarketOS edge + Lomiri
pmaports у pmbootstrap — ветка v26.06, `postmarketos-ui-lomiri` есть только в edge, поэтому корень ставится `apk.static` напрямую
с репозиториями телефона (`image/repositories`) и отдельным кэшем:
```sh
R=$PWD/rootfs; mkdir -p $R/etc/apk; cp image/repositories $R/etc/apk/repositories
sudo cp -a ~/.local/var/pmbootstrap/config_apk_keys $R/etc/apk/keys
sudo ~/.local/var/pmbootstrap/apk.static --arch aarch64 --root $R --initdb --cache-dir $PWD/apk-cache \
     --allow-untrusted add $(grep -v '^#' image/world-003.txt)
```
Состав (`world-003.txt`): база как у телефона (`postmarketos-base`, `-systemd`, `postmarketos-mkinitfs`, sudo-rs),
`postmarketos-ui-lomiri`, `lomiri-ui-extras-qt5`, `maliit-keyboard`, индикаторы ayatana, ModemManager, rmtfs, tqftpserv, hexagonrpcd,
qrtr, libssc, iio-sensor-proxy, `postmarketos-usb-moded`, Megapixels, Firefox, Organic Maps, приложения Lomiri.
Пакеты, доставленные на телефон позже, — `image/phone-world.txt`.

### 8.2. Слой железа m52xq
`image/build-layer.sh` накладывает по порядку:
1. оверлей Plasma-порта (`samsung-m52xq-mainline/rootfs-overlay`) без Plasma/KDE;
2. слой, снятый с телефона только чтением (прошивки, `/etc/m52xq`, реестр датчиков, `/usr/local`, udev, NM/ssh/polkit, юниты `m52xq-*`) —
   **в репозиторий не входит**, это личные данные и закрытые прошивки телефона: установщик берёт их с вашего телефона сам;
3. исправления Lomiri: заглушки LightDM.IntegratedLightDM и SystemSettings.Update, обёртки `lomiri-bin`, maliit на wayland, deviceinfo (GridUnit 21);
4. `image/extra-003`: сеанс tinydm, свой `fstab` (журналы, coredump, кэш apk — на userdata; домашний каталог в образе), портрет по умолчанию;
5. модули ядра и пакет устройства `image/device-pkg`.

Отличия свежего edge, учтённые вручную: `/lib`, `/sbin` — настоящие каталоги (прошивки в `/lib/firmware`, ссылки из `/usr/lib/firmware`);
`fastrpc` = 103:105 (реестр датчиков переназначается установщиком); пользователь `user` 10000:10000, группы wheel audio input video
netdev plugdev feedbackd; права каталогов восстановлены по базе apk; выключены `hexagonrpcd-sdsp` и `routewrangler`.

### 8.3. Правки версий 2 – v1
Наложить `rootfs-overlay/` поверх корня (владелец root, права как в оверлее) и собрать двоичные файлы из `build/` (раздел 9):
```sh
sudo cp -a --no-preserve=ownership rootfs-overlay/. $R/
sudo rm $R/EXCLUDED-FILES.txt
sudo chroot $R glib-compile-schemas /usr/share/glib-2.0/schemas
```
Двоичные файлы и модули перечислены в `rootfs-overlay/EXCLUDED-FILES.txt` с md5 — так можно сверить свою сборку.

### 8.4. Образ релиза (снимок настроенного телефона)
`image/build-v8-image.sh` снимает корень с телефона по USB (GNU tar 1.35 с xattr и file capabilities; busybox tar их теряет;
на время копирования сон запрещён через `systemd-inhibit`) в свежий ext4, сохраняя разметку, `pmOS_boot` и чистый `/home` базового образа:
```sh
OLD=base-v3.img NEW=samsung-m52xq-lomiri-v1-release.img PATTERNS=личные-значения.txt ./image/build-v8-image.sh
```
Что исключается: `/home`, журналы, кэши, coredump, сети Wi-Fi (`<HOME-WIFI>*` — впишите имена своих профилей), пары Bluetooth,
выбор SIM (`etc/m52xq/{bt_addr,data-sim,sim-mode,sms-sim}`), ключи `etc/ssh/ssh_host_*`, machine-id (остаётся пустым),
закрытые прошивки (`lib/firmware/{adsp*,modem*,a660_zap*,yupik_ipa_fws*,qca/*,qcom/vpu-2.0/*}`) и конфиги/реестр датчиков.
Пароль `root` и `user` ставится 1111. В конце скрипт ищет в образе личные значения (адрес Bluetooth и MAC, IMEI, IMSI, ICCID, номера,
хэши паролей, строки из `PATTERNS`) и падает, если находит.

### 8.5. Архив
Чанки образа v1 те же, что у прошитого и проверенного архива; ядро — из релиза kernel-7.1.13 под именами, которые ждёт установщик.
`mainline-extras` должен содержать хотя бы один файл: блок копирования прошивок с телефона вложен в проверку `mainline-extras/rootfs-files`.
```sh
mkdir -p archive/data/rootfs-chunks archive/firmware archive/mainline-extras/rootfs-files/etc/m52xq archive/mainline-extras/rootfs-files/etc/polkit-1/rules.d
split -b 2479603712 -d -a 1 samsung-m52xq-lomiri-v1-release.img archive/data/rootfs-chunks/samsung-m52xq.img.part-
cp -a installer/META-INF archive/
cp boot.img        archive/firmware/boot_v256_k7.1.13_panel-sleep.img
cp vendor_boot.img archive/firmware/vendor_boot_m52xq-local-v35-rtc.img
cp dtbo-frag.img   archive/firmware/dtbo-frag-m52xq.img
cp rootfs-overlay/etc/polkit-1/rules.d/50-m52xq-timedate.rules archive/mainline-extras/rootfs-files/etc/polkit-1/rules.d/
echo "postmarketos-lomiri v1" > archive/mainline-extras/rootfs-files/etc/m52xq/lomiri-release
find archive -xtype l                                     # битых ссылок быть не должно
cd archive && zip -9 -r ../postmarketos-lomiri-m52xq-mainline-v1-UNOFFICIAL.zip . && cd ..   # изнутри папки, без префикса
unzip -t postmarketos-lomiri-m52xq-mainline-v1-UNOFFICIAL.zip | tail -1
```
Файлы, которые уже есть в образе, в `mainline-extras` повторно не кладутся.

## 9. Пересобранные программы (`build/`)

| Папка | Что изменено |
|---|---|
| `v2/maliit-qt6` | maliit-framework под Qt6 (CMake из ветки master и PR 125) |
| `v3/integratedlightdm` | заглушка LightDM для Lomiri без lightdm (патчи 0001–0006, APKBUILD) |
| `v3/lomiri-app-launch` | `0002-m52xq-posix-reap-children-per-app-pids-stop` — завершение процессов приложения |
| `v3/lomiri-launcher`, `v3/lomiri-shell` | индекс ярлыка в момент нажатия; два обоя (рабочий стол / блокировка) |
| `v3/lomiri-system-settings` | «О телефоне» под mainline (IMEI из ModemManager, ОС, лицензии apk), яркость, перевод ru |
| `v3/lomiri-camera-app`, `v5/lomiri-camera-app` | QZXing необязателен, видео 4K, 16 Мп с биннингом |
| `v3/m52xqcamsrc`, `v5/…`, `v6/…`, `v7/m52xqcamsrc` | свой GStreamer-источник камеры: аппаратное кодирование Venus, автофокус, цифровой зум до 4x (v7) |
| `v3/libcamera` | APKBUILD + патчи soft-ISP (ремозаика tetracell S5KGW3, без записи в сенсор без AGC) |
| `v3/plasma-dialer`, `v4/dialer-*`, `v4/incoming-call`, `v6/plasma-dialer` | 2 SIM, звонок поверх блокировки, «добавить контакт», SIM в журнале, решение о звонке в Lomiri, полоска звонка |
| `v4/spacebar-multimodem` | SMS на нескольких модемах |
| `v4/calls-lockedapp` | Shell.qml: звонилка поверх экрана блокировки; в v1 — возврат экрана блокировки после звонка во сне |
| `v3/powerkey` | `m52xq-powerkey` v2: бездействие, «не выключать экран», сон |
| `v3/qmlkonsole` | панель клавиш над экранной клавиатурой |
| `v3/aa-shim`, `v3/cellular`, `v3/indicator-bluetooth` | заглушка AppArmor для click, модуль сотовой связи настроек, индикатор Bluetooth |
| `v3/translations` | русские переводы настроек и индикатора питания |
| `v5/ath11k-ahb` | `ahb.c` с повтором выхода из сна (WoWLAN; в v1 правка ath11k вошла в ядро) |
| `v6/modemmanager` | исправлено падение при подключении данных (use-after-free) |
| `v6/kpeople`, `v6/qtorganizer5-eds` | падение KPeople (база в двух потоках); календарь/будильник |
| `v6/megapixels`, `v7/…` | Megapixels под Lomiri (масштаб, кнопки в портретной и альбомной) |
| `v7/kirigami` | ColumnView не запускает пустую анимацию на каждом касании (патч под 6.31) — быстрый набор |
| `v7/gps` | прослойка `m52xq-gps-alt` (LD_PRELOAD) для lomiri-location-service с gpsd ≥ 3.20; XTRA |
| `v7/sim` | менеджер SIM: переключатель мобильных данных, синхронизация со шторкой |

Сборка — в chroot pmbootstrap (aarch64, `--arch aarch64`) или Alpine-chroot; точные команды каждой сборки — в
`docs/КОМАНДЫ-УБУНТУТАЧ24.md` и `docs/ЖУРНАЛ-УБУНТУТАЧ24.md`.

## 10. Службы и скрипты Lomiri-слоя

| Служба / скрипт | Назначение |
|---|---|
| `m52xq-start-lomiri` | запуск сеанса Lomiri (PATH с lomiri-bin, QML2_IMPORT_PATH, GRID_UNIT_PX=21) |
| `m52xq-powerkey` (+ .service) | короткое нажатие питания: блокировка и гашение / включение экрана, сон |
| `m52xq-osk-bridge` | экранная клавиатура для text-input-v3 (Firefox): input_method_v2 ↔ maliit-server |
| `m52xq-ringtone` | мелодия и вибрация входящего звонка модема |
| `m52xq-incall-proximity` | гашение экрана у уха во время звонка |
| `m52xq-audio-route`, `m52xq-voip-audio` | маршрут звука звонка; звук звонков Telegram в разговорном динамике |
| `m52xq-messaging-bridge` | непрочитанные SMS в индикаторе сообщений Lomiri |
| `m52xq-sim-slots`, `m52xq-sim-mode-menu` | номер слота каждой SIM (ICCID), менеджер SIM: питание, режим, SIM данных, переключатель данных |
| `m52xq-gnss-gpsd`, `m52xq-gps-xtra` (+ .timer), `m52xq-gps-restore` | GNSS ModemManager (NMEA по порядку) → gpsd; загрузка данных XTRA в модем после старта |
| `m52xq-wow-params`, хуки сна `m52xq-wifi-sleep`, `m52xq-nm-keep-wifi`, `m52xq-wifi-dark` | WoWLAN/APF, Wi-Fi подключён во сне, экран не вспыхивает при пробуждениях по сети |
| `m52xq-spacebar-sleep`, `m52xq-quiet-sleep`, `m52xq-timesyncd.sh` | SMS во сне, тихий сон, синхронизация времени после сна |
| `m52xq-audio-reprobe`, `m52xq-audio-rescue`, `m52xq-tfa-guard` | повтор пробы VA-макро LPASS после гонки старта ADSP, восстановление звука, усилитель TFA |
| `m52xq-venus-load`, `m52xq-virtualcam`, `m52xq-camera-postprocess` | загрузка модулей Venus, виртуальная камера, обработка снимков |
| `m52xq-megapixels-lomiri` | запуск Megapixels под Lomiri |
| `m52xq-reboot-recovery` | меню питания: перезагрузка в recovery |
| `m52xq-app-env` | окружение запуска приложений (масштаб, переменные Qt) |
| `m52xq-zram` | подкачка zram |
| `etc/polkit-1/rules.d/50-m52xq-timedate.rules` | смена часового пояса из мастера и настроек без пароля администратора |

Общие службы железа (модем, звук, датчики, Wi-Fi, сон, NFC) — в репозитории Plasma-порта.

## 11. Ловушки

- Lomiri-телефония (`lomiri-telephony-service`) требует telepathy-ofono, у нас модем через ModemManager — поэтому звонки и SMS сделаны plasma-dialer и Spacebar.
- `iio-sensor-proxy` поворачивал окна приложений → касания попадали мимо; ориентация по умолчанию — портрет.
- Не ставить на телефон dev-пакеты, которые понижают systemd/libc; `apk upgrade` заменяет наши сборки. Перед `apk add` смотреть, что он хочет удалить.
- Индикатор сети Lomiri работает в области сеанса (у него нет юнита): перезапускать через `systemd-run --user`, а не `setsid` из ssh.
- `pkill -f` в ssh-команде убивает свою же сессию — завершать по PID.
- zip собирать только изнутри папки архива (`cd archive && zip -9 -r ../x.zip .`), иначе TWRP не найдёт `META-INF`.
- `losetup` образа — обязательно `--sector-size 4096`, иначе разделы p1/p2 не видны.
- Снимок с телефона — только GNU tar: busybox tar не знает `--null`/`-T` и не сохраняет xattr.

## 12. Благодарности
postmarketOS и pmbootstrap; UBports и Lomiri; Alpine Linux; KDE (plasma-dialer, Spacebar, Kirigami); разработчикам mainline Linux
для Qualcomm SC7280/QCM6490 (Fairphone 5 и другие).
