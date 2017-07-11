ARCHS = armv7 arm64
TARGET = iphone:clang:latest:latest

include theos/makefiles/common.mk

BUNDLE_NAME = NotificationTesterPrefs
NotificationTesterPrefs_FILES = NotificationTesterPrefs.mm
NotificationTesterPrefs_INSTALL_PATH = /Library/PreferenceBundles
NotificationTesterPrefs_FRAMEWORKS = UIKit
NotificationTesterPrefs_PRIVATE_FRAMEWORKS = Preferences

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/NotificationTesterPrefs.plist$(ECHO_END)
