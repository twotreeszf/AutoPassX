TARGET = iphone:latest:10.0
PACKAGE_VERSION = 1.0.0
DEBUG = 0
include $(THEOS)/makefiles/common.mk

TWEAK_NAME = AutoPassX
AutoPassX_CFLAGS = -fobjc-arc -w
AutoPassX_FILES = Tweak.xm

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
SUBPROJECTS += autopassxprefer
include $(THEOS_MAKE_PATH)/aggregate.mk
