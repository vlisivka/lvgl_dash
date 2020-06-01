#include "lvgl/lvgl.h"
#include "init.h"
#include <unistd.h>
#include <pthread.h>
#include <time.h>
#include <sys/time.h>

#define DISP_BUF_SIZE (80 * LV_HOR_RES_MAX)

int main(void)
{
    init();

    /*Create a Demo*/
    //lv_demo_widgets();
    lv_demo_keypad_encoder();

    /*Handle LitlevGL tasks (tickless mode)*/
    while(1) {
        lv_task_handler();
        usleep(5000);
    }

    return 0;
}


void lv_lua_event_cb_caller(lv_obj_t * obj, lv_event_t event) {
  /* Do nothing. */
}
