ARCHS = armv7 arm64
TARGET = iphone:clang:latest:latest
THEOS_BUILD_DIR = debs

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = NotificationTester
NotificationTester_FILES = Tweak.xm
NotificationTester_FRAMEWORKS = UIKit
NotificationTester_LIBRARIES = bulletin sqlite3

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
SUBPROJECTS += notificationtesterprefs
include $(THEOS_MAKE_PATH)/aggregate.mk
