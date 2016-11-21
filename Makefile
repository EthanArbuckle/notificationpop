include theos/makefiles/common.mk

TWEAK_NAME = NotificationPop
NotificationPop_FILES = Tweak.xm
NotificationPop_FRAMEWORKS = IOKit

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
