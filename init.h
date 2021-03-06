#ifndef _INIT_H
#define _INIT_H
#include "lv_ex_conf.h"
#include "lv_examples/lv_examples.h"
#include "lv_drivers/indev/evdev.h"
#include "lua.h"

int init_app();

lv_indev_t * init_keyboard();

void store_lua_state(lua_State *L);
lua_State* get_lua_state();

void event_loop(lua_State *L);

static lv_style_t lv_new_style() {
  lv_style_t style;
  lv_style_init(&style);
  return style;
}

#endif
