#
# Makefile
#
#CC ?= gcc
CC = /opt/scel/18.10/sysroots/x86_64-scelsdk-linux/usr/bin/arm-scel-linux-gnueabi/arm-scel-linux-gnueabi-gcc
ARM_CFLAGS = --sysroot=/opt/scel/18.10/sysroots/armv7ahf-neon-scel-linux-gnueabi -mcpu=cortex-a9 -mfpu=neon -mfloat-abi=hard -marm
CRANKSOFTWARE_PREFIX ?= ${HOME}/workspace/dash2-clean/shim/deps/Crank_Software/Storyboard_Engine/5.2.201802081110/linux-imx6yocto-armle-swrender-obj
LVGL_DIR_NAME ?= lvgl
LVGL_DIR ?= ${shell pwd}
CFLAGS ?= -O3 -g0 -I$(LVGL_DIR)/ -Wall -Wshadow -Wundef -Wmaybe-uninitialized -Wmissing-prototypes -Wno-discarded-qualifiers -Wall -Wextra -Wno-unused-function -Wundef -Wno-error=strict-prototypes -Wpointer-arith -fno-strict-aliasing -Wno-error=cpp -Wuninitialized -Wmaybe-uninitialized -Wno-unused-parameter -Wno-missing-field-initializers -Wtype-limits -Wsizeof-pointer-memaccess -Wno-format-nonliteral -Wno-cast-qual -Wunreachable-code -Wno-switch-default -Wno-switch-enum -Wreturn-type -Wmultichar -Wformat-security -Wno-ignored-qualifiers -Wno-error=pedantic -Wno-sign-compare -Wno-error=missing-prototypes -Wdouble-promotion -Wclobbered -Wdeprecated -Wempty-body -Wtype-limits -Wshift-negative-value -Wstack-usage=1024 -Wno-unused-value -Wno-unused-parameter -Wno-missing-field-initializers -Wuninitialized -Wmaybe-uninitialized -Wall -Wextra -Wno-unused-parameter -Wno-missing-field-initializers -Wtype-limits -Wsizeof-pointer-memaccess -Wno-format-nonliteral -Wpointer-arith -Wno-cast-qual -Wmissing-prototypes -Wunreachable-code -Wno-switch-default -Wswitch-enum -Wreturn-type -Wmultichar -Wno-discarded-qualifiers -Wformat-security -Wno-ignored-qualifiers -Wno-sign-compare \
   -fPIC -I$(CRANKSOFTWARE_PREFIX)/include/lua $(ARM_CFLAGS)
LDFLAGS ?= -lSDL2 -lm \
  -L$(CRANKSOFTWARE_PREFIX)/lib/ -lsblua -lgre -pthread
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

SRCS = $(ASRCS) $(CSRCS) $(MAINSRC) lv_demo_keypad_encoder.c init.c lvgl_wrap.c
OBJS = $(AOBJS) $(COBJS) init.o lvgl_wrap.o

## MAINOBJ -> OBJFILES

.PHONY: all
all: default

%.o: %.c
	@$(CC)  $(CFLAGS) -c $< -o $@
	@echo "CC $<"

demo: default

.PHONY: default
default: $(OBJS) $(MAINOBJ)
	$(CC) -o $(BIN) $(MAINOBJ) $(AOBJS) $(COBJS) init.o $(LDFLAGS) $(CFLAGS)

.PHONY: clean
clean: 
	rm -f $(BIN) $(OBJS) $(MAINOBJ) lvgl_wrap.o lvgl_wrap.c *.so

lvgl_wrap.c: lvgl.i init.h
	swig -lua lvgl.i

lvgl.so: lvgl_wrap.o init.o $(OBJS)
	$(CC) $(LDFLAGS) $(CFLAGS)  $(OBJS) -shared -o $@

.PHONY: up
up: lvgl.so
	scp lvgl.so dash:/usr/local/lib/lua/5.1/
	scp user-script dash:/usr/bin/

.PHONY: upd
upd: default
	scp demo dash:/usr/bin/
