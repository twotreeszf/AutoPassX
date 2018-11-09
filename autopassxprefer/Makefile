include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = AutoPassXPrefer
AutoPassXPrefer_FILES = TTRootListController.m
AutoPassXPrefer_INSTALL_PATH = /Library/PreferenceBundles
AutoPassXPrefer_FRAMEWORKS = UIKit
AutoPassXPrefer_PRIVATE_FRAMEWORKS = Preferences

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/AutoPassXPrefer.plist$(ECHO_END)
