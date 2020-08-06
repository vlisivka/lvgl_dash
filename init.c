#include "lvgl/lvgl.h"
#include "lv_drivers/display/fbdev.h"
#include "lv_examples/lv_examples.h"
#include "init.h"
#include "virt_keyboard.h"
#include <unistd.h>
#include <pthread.h>
#include <time.h>
#include <sys/time.h>
#include <stdio.h>

#define DISP_BUF_SIZE (80 * LV_HOR_RES_MAX)

/** Get Lua state, stored by event_loop() function. */
static pthread_key_t lua_state_key;
static pthread_once_t key_once = PTHREAD_ONCE_INIT;

static void make_lua_state_key() {
    (void) pthread_key_create(&lua_state_key, NULL);
}

static void init_lua_state_key() {
    /* Make thread-local variable to store Lua state. */
    pthread_once(&key_once, make_lua_state_key);
}

/** Store Lua state for later use by callbacks */
void store_lua_state(lua_State *L) {
    (void) pthread_setspecific(lua_state_key, L);
}

/** Get Lua state, stored by event_loop() function. */
lua_State* get_lua_state() {
    return pthread_getspecific(lua_state_key);
}


int init_app()
{

    /*LittlevGL init*/
    lv_init();

    /*Linux frame buffer device init*/
    fbdev_init();

    /*A small buffer for LittlevGL to draw the screen's content*/
    static lv_color_t buf[DISP_BUF_SIZE];

    /*Initialize a descriptor for the buffer*/
    static lv_disp_buf_t disp_buf;
    lv_disp_buf_init(&disp_buf, buf, NULL, DISP_BUF_SIZE);

    /*Initialize and register a display driver*/
    lv_disp_drv_t disp_drv;
    lv_disp_drv_init(&disp_drv);
    disp_drv.buffer   = &disp_buf;
    disp_drv.flush_cb = fbdev_flush;
    lv_disp_drv_register(&disp_drv);

    /* Make thread-local variable to store Lua state. */
    init_lua_state_key();

    return 0;
}

static lv_indev_drv_t virt_keyboard_drv;
lv_indev_t * init_keyboard() {
    virt_keyboard_init();
    lv_indev_drv_init(&virt_keyboard_drv);
    virt_keyboard_drv.type = LV_INDEV_TYPE_KEYPAD_ENCODER;
    virt_keyboard_drv.read_cb = virt_keyboard_read;
    lv_indev_t * virt_keyboard_indev = lv_indev_drv_register(&virt_keyboard_drv);
    
    return virt_keyboard_indev;
}

/*Set in lv_conf.h as `LV_TICK_CUSTOM_SYS_TIME_EXPR`*/
uint32_t custom_tick_get(void)
{
    static uint64_t start_ms = 0;
    if(start_ms == 0) {
        struct timeval tv_start;
        gettimeofday(&tv_start, NULL);
        start_ms = (tv_start.tv_sec * 1000000 + tv_start.tv_usec) / 1000;
    }

    struct timeval tv_now;
    gettimeofday(&tv_now, NULL);
    uint64_t now_ms;
    now_ms = (tv_now.tv_sec * 1000000 + tv_now.tv_usec) / 1000;

    uint32_t time_ms = now_ms - start_ms;
    return time_ms;
}



void event_loop(lua_State *L)
{
    store_lua_state(L);

    /*Handle LitlevGL tasks (tickless mode)*/
    while(1) {
        lv_task_handler();
        usleep(5000);
    }
}
