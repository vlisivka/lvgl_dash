#
# Makefile
#

# Requirements:
# Dash M50 device, for running the code. Dash L50 will work too, but image will be flipped.
# Dash SCEL SDK ,for crosscompilation. Other ARM crosscompilers may work too, not tested.
# CrankSoftware StoryBoard-5.2, for sblua-5.1 headers and libraries. Stock Lua 5.1 may work too, not tested.
# SWIG, for binding generation.
# For screen recording, ffmpeg must be installed on Dash.

# Adjust these options according to your situation:
# Crosscompiler to use
CC = /opt/scel/18.10/sysroots/x86_64-scelsdk-linux/usr/bin/arm-scel-linux-gnueabi/arm-scel-linux-gnueabi-gcc
# Crosscompiler flags
ARM_CFLAGS = --sysroot=/opt/scel/18.10/sysroots/armv7ahf-neon-scel-linux-gnueabi -mcpu=cortex-a9 -mfpu=neon -mfloat-abi=hard -marm
# Path to sblua (StoryBoard-5.2 Lua-5.1) libraries
CRANKSOFTWARE_PREFIX ?= ${HOME}/workspace/dash2-clean/shim/deps/Crank_Software/Storyboard_Engine/5.2.201802081110/linux-imx6yocto-armle-swrender-obj

LVGL_DIR_NAME ?= lvgl
LVGL_DIR ?= ${shell pwd}
CFLAGS ?= -I$(LVGL_DIR)/ -Wall -Wshadow -Wundef -Wmaybe-uninitialized -Wmissing-prototypes -Wno-discarded-qualifiers -Wall -Wextra -Wno-unused-function -Wundef -Wno-error=strict-prototypes -Wpointer-arith -fno-strict-aliasing -Wno-error=cpp -Wuninitialized -Wmaybe-uninitialized -Wno-unused-parameter -Wno-missing-field-initializers -Wtype-limits -Wsizeof-pointer-memaccess -Wno-format-nonliteral -Wno-cast-qual -Wunreachable-code -Wno-switch-default -Wno-switch-enum -Wreturn-type -Wmultichar -Wformat-security -Wno-ignored-qualifiers -Wno-error=pedantic -Wno-sign-compare -Wno-error=missing-prototypes -Wdouble-promotion -Wclobbered -Wdeprecated -Wempty-body -Wtype-limits -Wshift-negative-value -Wstack-usage=1024 -Wno-unused-value -Wno-unused-parameter -Wno-missing-field-initializers -Wuninitialized -Wmaybe-uninitialized -Wall -Wextra -Wno-unused-parameter -Wno-missing-field-initializers -Wtype-limits -Wsizeof-pointer-memaccess -Wno-format-nonliteral -Wpointer-arith -Wno-cast-qual -Wmissing-prototypes -Wunreachable-code -Wno-switch-default -Wswitch-enum -Wreturn-type -Wmultichar -Wno-discarded-qualifiers -Wformat-security -Wno-ignored-qualifiers -Wno-sign-compare \
   -fPIC -I$(CRANKSOFTWARE_PREFIX)/include/lua $(ARM_CFLAGS)
LDFLAGS ?= -lSDL2 -lm \
  -L$(CRANKSOFTWARE_PREFIX)/lib/ -lsblua -lgre -pthread

# No debug info
CFLSGS += -O3 -g0
# Debug info and stack trace
#CFLSGS += -O0 -ggdb
#LDFLAGS += -lSegFault

BIN = demo

# Whole program optimization reduces `demo` binary size by 2x
#CFLAGS += -flto

#Collect the files to compile
MAINSRC = ./main.c

include $(LVGL_DIR)/lvgl/lvgl.mk
include $(LVGL_DIR)/lv_drivers/lv_drivers.mk
include $(LVGL_DIR)/lv_examples/lv_examples.mk

OBJEXT ?= .o

AOBJS = $(ASRCS:.S=$(OBJEXT))
COBJS = $(CSRCS:.c=$(OBJEXT))

MAINOBJ = $(MAINSRC:.c=$(OBJEXT))

SRCS = $(ASRCS) $(CSRCS) $(MAINSRC) lv_demo_keypad_encoder.c init.c lvgl_wrap.c virt_keyboard.c
OBJS = $(AOBJS) $(COBJS) init.o lvgl_wrap.o virt_keyboard.o

## MAINOBJ -> OBJFILES

.PHONY: all
all: default

%.o: %.c
	@$(CC)  $(CFLAGS) -c $< -o $@
	@echo "CC $<"

demo: default

.PHONY: default
default: $(OBJS) $(MAINOBJ)
	$(CC) -o $(BIN) $(MAINOBJ) $(AOBJS) $(COBJS) init.o virt_keyboard.o $(LDFLAGS) $(CFLAGS)

.PHONY: clean
clean: 
	rm -f $(BIN) $(OBJS) $(MAINOBJ) lvgl_wrap.o lvgl_wrap.c *.so

lvgl_wrap.c: lvgl.i init.h
	swig -lua lvgl.i

lvgl.so: $(OBJS)
	$(CC) $(LDFLAGS) $(CFLAGS)  $(OBJS) -shared -o $@

.PHONY: up
up: lvgl.so default
	scp lvgl.so nanomsg/nanomsg.so dash:/usr/lib/sblua-5.2/
	scp dash.lua dash:/usr/share/sblua-5.2/
	scp demo user-script *.lua ffmpeg-recorder-wrapper.sh dash:/usr/bin/
	scp launcher.conf ffmpeg-recorder.conf dash:/etc/event-server.d/
	ssh dash mkdir -p /usr/share/applications/
	scp *.desktop dash:/usr/share/applications/
