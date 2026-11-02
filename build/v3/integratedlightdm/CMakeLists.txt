# m52xq (убунтутач24/003): only the IntegratedLightDM QML plugin of lomiri 0.6.2 (PAM lock screen), which the Alpine
# package drops (0004-Disable-lightdm-integration.patch); a full lomiri configure needs Lomiri API .pc files Alpine lacks
cmake_minimum_required(VERSION 3.16)
project(m52xq-integratedlightdm CXX)
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_AUTOMOC ON)
find_package(Qt5 REQUIRED COMPONENTS Core Gui DBus Qml Quick Concurrent)
find_package(PkgConfig REQUIRED)
pkg_check_modules(GLIB REQUIRED glib-2.0)
pkg_check_modules(LIBUSERMETRICSOUTPUT REQUIRED libusermetricsoutput-1)
set(L ${CMAKE_SOURCE_DIR}/lomiri-0.6.2)
set(D ${L}/plugins/LightDM)
include_directories(${D} ${D}/IntegratedLightDM ${D}/IntegratedLightDM/liblightdm ${L}/plugins/Utils
	${L}/plugins/AccountsService ${L}/src/liblomiri-private ${CMAKE_CURRENT_BINARY_DIR}
	${GLIB_INCLUDE_DIRS} ${LIBUSERMETRICSOUTPUT_INCLUDE_DIRS})
add_definitions(-DINTEGRATED_LIGHTDM -DQT_NO_KEYWORDS -DPLUGIN_CLASSNAME=IntegratedLightDM -DSHELL_APP_FULL_DIR=\"/usr/share/lomiri\")
add_library(integratedLightDM STATIC
	${D}/IntegratedLightDM/liblightdm/Greeter.cpp ${D}/IntegratedLightDM/liblightdm/SessionsModel.cpp
	${D}/IntegratedLightDM/liblightdm/UsersModel.cpp ${D}/IntegratedLightDM/liblightdm/GreeterPrivate.cpp
	${D}/IntegratedLightDM/liblightdm/SessionsModelPrivate.cpp ${D}/IntegratedLightDM/liblightdm/UsersModelPrivate.cpp
	${L}/plugins/AccountsService/AccountsServiceDBusAdaptor.cpp ${L}/plugins/Utils/qvariantlistmodel.cpp)
set_target_properties(integratedLightDM PROPERTIES COMPILE_FLAGS "-DSM_BUSNAME=systemBus -fPIC")
target_link_libraries(integratedLightDM ${GLIB_LIBRARIES} ${LIBUSERMETRICSOUTPUT_LDFLAGS} -lpam Qt5::Concurrent Qt5::DBus Qt5::Gui)
add_library(IntegratedLightDM-qml MODULE
	${L}/plugins/Utils/lomirisortfilterproxymodelqml.cpp ${D}/DBusGreeter.cpp ${D}/DBusGreeterList.cpp ${D}/Greeter.cpp
	${D}/plugin.cpp ${D}/PromptsModel.cpp ${D}/SessionsModel.cpp ${D}/UsersModel.cpp)
target_link_libraries(IntegratedLightDM-qml integratedLightDM ${CMAKE_SOURCE_DIR}/lib-private/liblomiri-private.so.0
	${LIBUSERMETRICSOUTPUT_LDFLAGS} Qt5::DBus Qt5::Gui Qt5::Qml Qt5::Quick)
