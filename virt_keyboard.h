/**
 * @file virt_keyboard.h
 *
 */

#ifndef VIRT_KEYBOARD_H
#define VIRT_KEYBOARD_H

#ifdef __cplusplus
extern "C" {
#endif

/*********************
 *      INCLUDES
 *********************/
#ifndef LV_DRV_NO_CONF
#ifdef LV_CONF_INCLUDE_SIMPLE
#include "lv_drv_conf.h"
#else
#include "../../lv_drv_conf.h"
#endif
#endif

#ifdef LV_LVGL_H_INCLUDE_SIMPLE
#include "lvgl.h"
#else
#include "lvgl/lvgl.h"
#endif


/*********************
 *      DEFINES
 *********************/

/**********************
 *      TYPEDEFS
 **********************/

/**********************
 * GLOBAL PROTOTYPES
 **********************/
/**
 * Initialize the keyboard
 */
void virt_keyboard_init(void);

/**
 * Get the last pressed or released character from the PC's keyboard
 * @param indev_drv pointer to the related input device driver
 * @param data store the read data here
 * @return false: because the points are not buffered, so no more data to be read
 */
bool virt_keyboard_read(lv_indev_drv_t * indev_drv, lv_indev_data_t * data);

/**
 * It is called periodically from the SDL thread to check a key is pressed/released
 * @param event describes the event
 */
void lv_virt_keyboard_handler(uint32_t a_last_key, lv_indev_state_t a_state);

/**********************
 *      MACROS
 **********************/

#ifdef __cplusplus
} /* extern "C" */
#endif

#endif /*VIRT_KEYBOARD_H*/
