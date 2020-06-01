#ifndef _INIT_H
#define _INIT_H
#include "lv_ex_conf.h"
#include "lv_examples/lv_examples.h"
#include "lv_drivers/indev/evdev.h"
#include "lua.h"

int init();

lv_indev_t * init_keyboard();

lua_State* get_lua_state();

void event_loop(lua_State *L);

#endif
