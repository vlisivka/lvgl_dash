/**
 * @file virt_keyboard.c
 *
 */

/*********************
 *      INCLUDES
 *********************/
#include "virt_keyboard.h"

/*********************
 *      DEFINES
 *********************/

/**********************
 *      TYPEDEFS
 **********************/

/**********************
 *  STATIC PROTOTYPES
 **********************/

/**********************
 *  STATIC VARIABLES
 **********************/
static uint32_t last_key;
static lv_indev_state_t state;

/**********************
 *      MACROS
 **********************/

/**********************
 *   GLOBAL FUNCTIONS
 **********************/

/**
 * Initialize the keyboard
 */
void virt_keyboard_init(void)
{
    /*Nothing to init*/
}

/**
 * Get the last pressed or released character from the PC's keyboard
 * @param indev_drv pointer to the related input device driver
 * @param data store the read data here
 * @return false: because the points are not buffered, so no more data to be read
 */
bool virt_keyboard_read(lv_indev_drv_t * indev_drv, lv_indev_data_t * data)
{
    (void) indev_drv;      /*Unused*/
    data->state = state;
    data->key = last_key;

    return false;
}

/**
 * It is called periodically from the SDL thread to check a key is pressed/released
 * @param event describes the event
 */
void lv_virt_keyboard_handler(uint32_t a_last_key, lv_indev_state_t a_state)
{
    last_key = a_last_key;
    state = a_state;
}

/**********************
 *   STATIC FUNCTIONS
 **********************/
