ARCHS = arm64
TARGET = iphone:clang:latest:10.0

include $(THEOS)/makefiles/common.mk

LIBRARY_NAME = libfiledialog
libfiledialog_FILES = $(wildcard *.m)
libfiledialog_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/library.mk

after-install::
	install.exec "killall -9 SpringBoard"
