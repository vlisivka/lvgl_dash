%module lvgl

// Strip common prefix "lv_" and "LV_" from names
%rename("%(strip:[lv_])s", regexmatch$name="^lv_") "";
%rename("%(strip:[LV_])s", regexmatch$name="^LV_") "";

// Ignore all methods or constants starting with '_'
%rename("$ignore", regexmatch$name="^_") "";

// Cannot compile
%ignore lv_vsnprintf;

// For STM32 only
%ignore lv_gpu_stm32_dma2d_fill;
%ignore lv_gpu_stm32_dma2d_fill_mask;
%ignore lv_gpu_stm32_dma2d_copy;
%ignore lv_gpu_stm32_dma2d_blend;

// According to SWIG documenation, SWIG should be able to deduct this by itself,
// but it doesn't work because stdint.h file is not included.
%typemap(in) uint8_t = int;
%typemap(in) int8_t = int;
%typemap(in) uint16_t = int;
%typemap(in) int16_t = int;
%typemap(in) uint32_t = int;
%typemap(in) int32_t = int;


%{
#include "lv_conf.h"
#include "./lvgl/lvgl.h"
#include "./lvgl/src/lv_hal/lv_hal_disp.h"
#include "./lvgl/src/lv_hal/lv_hal_tick.h"
#include "./lvgl/src/lv_hal/lv_hal_indev.h"
#include "./lvgl/src/lv_hal/lv_hal.h"
#include "./lvgl/src/lv_widgets/lv_objx_templ.h"
#include "./lvgl/src/lv_widgets/lv_linemeter.h"
#include "./lvgl/src/lv_widgets/lv_tileview.h"
#include "./lvgl/src/lv_widgets/lv_imgbtn.h"
#include "./lvgl/src/lv_widgets/lv_label.h"
#include "./lvgl/src/lv_widgets/lv_msgbox.h"
#include "./lvgl/src/lv_widgets/lv_list.h"
#include "./lvgl/src/lv_widgets/lv_page.h"
#include "./lvgl/src/lv_widgets/lv_switch.h"
#include "./lvgl/src/lv_widgets/lv_roller.h"
#include "./lvgl/src/lv_widgets/lv_objmask.h"
#include "./lvgl/src/lv_widgets/lv_arc.h"
#include "./lvgl/src/lv_widgets/lv_line.h"
#include "./lvgl/src/lv_widgets/lv_checkbox.h"
#include "./lvgl/src/lv_widgets/lv_led.h"
#include "./lvgl/src/lv_widgets/lv_btnmatrix.h"
#include "./lvgl/src/lv_widgets/lv_table.h"
#include "./lvgl/src/lv_widgets/lv_calendar.h"
#include "./lvgl/src/lv_widgets/lv_btn.h"
#include "./lvgl/src/lv_widgets/lv_keyboard.h"
#include "./lvgl/src/lv_widgets/lv_img.h"
#include "./lvgl/src/lv_widgets/lv_spinner.h"
#include "./lvgl/src/lv_widgets/lv_win.h"
#include "./lvgl/src/lv_widgets/lv_gauge.h"
#include "./lvgl/src/lv_widgets/lv_chart.h"
#include "./lvgl/src/lv_widgets/lv_spinbox.h"
#include "./lvgl/src/lv_widgets/lv_bar.h"
#include "./lvgl/src/lv_widgets/lv_dropdown.h"
#include "./lvgl/src/lv_widgets/lv_canvas.h"
#include "./lvgl/src/lv_widgets/lv_textarea.h"
#include "./lvgl/src/lv_widgets/lv_cont.h"
#include "./lvgl/src/lv_widgets/lv_cpicker.h"
#include "./lvgl/src/lv_widgets/lv_tabview.h"
#include "./lvgl/src/lv_widgets/lv_slider.h"
#include "./lvgl/src/lv_api_map.h"
#include "./lvgl/src/lv_draw/lv_img_decoder.h"
#include "./lvgl/src/lv_draw/lv_draw_triangle.h"
#include "./lvgl/src/lv_draw/lv_draw_line.h"
#include "./lvgl/src/lv_draw/lv_draw_rect.h"
#include "./lvgl/src/lv_draw/lv_draw_arc.h"
#include "./lvgl/src/lv_draw/lv_img_buf.h"
#include "./lvgl/src/lv_draw/lv_draw_img.h"
#include "./lvgl/src/lv_draw/lv_img_cache.h"
#include "./lvgl/src/lv_draw/lv_draw.h"
#include "./lvgl/src/lv_draw/lv_draw_label.h"
#include "./lvgl/src/lv_draw/lv_draw_blend.h"
#include "./lvgl/src/lv_draw/lv_draw_mask.h"
#include "./lvgl/src/lv_core/lv_obj_style_dec.h"
#include "./lvgl/src/lv_core/lv_refr.h"
#include "./lvgl/src/lv_core/lv_disp.h"
#include "./lvgl/src/lv_core/lv_debug.h"
#include "./lvgl/src/lv_core/lv_group.h"
#include "./lvgl/src/lv_core/lv_obj.h"
#include "./lvgl/src/lv_core/lv_indev.h"
#include "./lvgl/src/lv_core/lv_style.h"
#include "./lvgl/src/lv_conf_internal.h"
#include "./lvgl/src/lv_font/lv_font.h"
#include "./lvgl/src/lv_font/lv_font_fmt_txt.h"
#include "./lvgl/src/lv_font/lv_symbol_def.h"
#include "./lvgl/src/lv_themes/lv_theme_empty.h"
#include "./lvgl/src/lv_themes/lv_theme_template.h"
#include "./lvgl/src/lv_themes/lv_theme.h"
#include "./lvgl/src/lv_themes/lv_theme_material.h"
#include "./lvgl/src/lv_themes/lv_theme_mono.h"
#include "./lvgl/src/lv_gpu/lv_gpu_stm32_dma2d.h"
#include "./lvgl/src/lv_misc/lv_types.h"
#include "./lvgl/src/lv_misc/lv_anim.h"
#include "./lvgl/src/lv_misc/lv_printf.h"
#include "./lvgl/src/lv_misc/lv_txt_ap.h"
#include "./lvgl/src/lv_misc/lv_utils.h"
#include "./lvgl/src/lv_misc/lv_templ.h"
#include "./lvgl/src/lv_misc/lv_log.h"
#include "./lvgl/src/lv_misc/lv_bidi.h"
#include "./lvgl/src/lv_misc/lv_color.h"
#include "./lvgl/src/lv_misc/lv_ll.h"
#include "./lvgl/src/lv_misc/lv_mem.h"
#include "./lvgl/src/lv_misc/lv_fs.h"
#include "./lvgl/src/lv_misc/lv_task.h"
#include "./lvgl/src/lv_misc/lv_async.h"
#include "./lvgl/src/lv_misc/lv_area.h"
#include "./lvgl/src/lv_misc/lv_txt.h"
#include "./lvgl/src/lv_misc/lv_math.h"
#include "./lvgl/src/lv_misc/lv_gc.h"
#include "init.h"
#include "virt_keyboard.h"
%}


#include <stdint.h>
%include "lv_conf.h"
%include "lvgl/lvgl.h"

%include "./lvgl/src/lv_hal/lv_hal_disp.h"
%include "./lvgl/src/lv_hal/lv_hal_tick.h"
%include "./lvgl/src/lv_hal/lv_hal_indev.h"
%include "./lvgl/src/lv_hal/lv_hal.h"
%include "./lvgl/src/lv_widgets/lv_objx_templ.h"
%include "./lvgl/src/lv_widgets/lv_linemeter.h"
%include "./lvgl/src/lv_widgets/lv_tileview.h"
%include "./lvgl/src/lv_widgets/lv_imgbtn.h"
%include "./lvgl/src/lv_widgets/lv_label.h"
%include "./lvgl/src/lv_widgets/lv_msgbox.h"
%include "./lvgl/src/lv_widgets/lv_list.h"
%include "./lvgl/src/lv_widgets/lv_page.h"
%include "./lvgl/src/lv_widgets/lv_switch.h"
%include "./lvgl/src/lv_widgets/lv_roller.h"
%include "./lvgl/src/lv_widgets/lv_objmask.h"
%include "./lvgl/src/lv_widgets/lv_arc.h"
%include "./lvgl/src/lv_widgets/lv_line.h"
%include "./lvgl/src/lv_widgets/lv_checkbox.h"
%include "./lvgl/src/lv_widgets/lv_led.h"
%include "./lvgl/src/lv_widgets/lv_btnmatrix.h"
%include "./lvgl/src/lv_widgets/lv_table.h"
%include "./lvgl/src/lv_widgets/lv_calendar.h"
%include "./lvgl/src/lv_widgets/lv_btn.h"
%include "./lvgl/src/lv_widgets/lv_keyboard.h"
%include "./lvgl/src/lv_widgets/lv_img.h"
%include "./lvgl/src/lv_widgets/lv_spinner.h"
%include "./lvgl/src/lv_widgets/lv_win.h"
%include "./lvgl/src/lv_widgets/lv_gauge.h"
%include "./lvgl/src/lv_widgets/lv_chart.h"
%include "./lvgl/src/lv_widgets/lv_spinbox.h"
%include "./lvgl/src/lv_widgets/lv_bar.h"
%include "./lvgl/src/lv_widgets/lv_dropdown.h"
%include "./lvgl/src/lv_widgets/lv_canvas.h"
%include "./lvgl/src/lv_widgets/lv_textarea.h"
%include "./lvgl/src/lv_widgets/lv_cont.h"
%include "./lvgl/src/lv_widgets/lv_cpicker.h"
%include "./lvgl/src/lv_widgets/lv_tabview.h"
%include "./lvgl/src/lv_widgets/lv_slider.h"
%include "./lvgl/src/lv_api_map.h"
%include "./lvgl/src/lv_draw/lv_img_decoder.h"
%include "./lvgl/src/lv_draw/lv_draw_triangle.h"
%include "./lvgl/src/lv_draw/lv_draw_line.h"
%include "./lvgl/src/lv_draw/lv_draw_rect.h"
%include "./lvgl/src/lv_draw/lv_draw_arc.h"
%include "./lvgl/src/lv_draw/lv_img_buf.h"
%include "./lvgl/src/lv_draw/lv_draw_img.h"
%include "./lvgl/src/lv_draw/lv_img_cache.h"
%include "./lvgl/src/lv_draw/lv_draw.h"
%include "./lvgl/src/lv_draw/lv_draw_label.h"
%include "./lvgl/src/lv_draw/lv_draw_blend.h"
%include "./lvgl/src/lv_draw/lv_draw_mask.h"
%include "./lvgl/src/lv_core/lv_obj_style_dec.h"
%include "./lvgl/src/lv_core/lv_refr.h"
%include "./lvgl/src/lv_core/lv_disp.h"
%include "./lvgl/src/lv_core/lv_debug.h"
%include "./lvgl/src/lv_core/lv_group.h"
%include "./lvgl/src/lv_core/lv_obj.h"
%include "./lvgl/src/lv_core/lv_indev.h"
%include "./lvgl/src/lv_core/lv_style.h"
%include "./lvgl/src/lv_conf_internal.h"
%include "./lvgl/src/lv_font/lv_font.h"
%include "./lvgl/src/lv_font/lv_font_fmt_txt.h"
%include "./lvgl/src/lv_font/lv_symbol_def.h"
%include "./lvgl/src/lv_themes/lv_theme_empty.h"
%include "./lvgl/src/lv_themes/lv_theme_template.h"
%include "./lvgl/src/lv_themes/lv_theme.h"
%include "./lvgl/src/lv_themes/lv_theme_material.h"
%include "./lvgl/src/lv_themes/lv_theme_mono.h"
%include "./lvgl/src/lv_gpu/lv_gpu_stm32_dma2d.h"
%include "./lvgl/src/lv_misc/lv_types.h"
%include "./lvgl/src/lv_misc/lv_anim.h"
%include "./lvgl/src/lv_misc/lv_printf.h"
%include "./lvgl/src/lv_misc/lv_txt_ap.h"
%include "./lvgl/src/lv_misc/lv_utils.h"
%include "./lvgl/src/lv_misc/lv_templ.h"
%include "./lvgl/src/lv_misc/lv_log.h"
%include "./lvgl/src/lv_misc/lv_bidi.h"
%include "./lvgl/src/lv_misc/lv_color.h"
%include "./lvgl/src/lv_misc/lv_ll.h"
%include "./lvgl/src/lv_misc/lv_fs.h"
%include "./lvgl/src/lv_misc/lv_task.h"
%include "./lvgl/src/lv_misc/lv_async.h"
%include "./lvgl/src/lv_misc/lv_area.h"
%include "./lvgl/src/lv_misc/lv_txt.h"
%include "./lvgl/src/lv_misc/lv_math.h"
%include "./lvgl/src/lv_misc/lv_gc.h"
%include "init.h"
%include "virt_keyboard.h"

%include <lua_fnptr.i>

%inline {
#include <pthread.h>

/**
 * Set a an event handler function for an object.
 * Used by the user to react on event which happens with the object.
 * @param obj pointer to an object
 * @param event_cb the new event function
 */
void obj_set_lua_event_cb(lua_State *L, lv_obj_t *obj, SWIGLUA_REF ref) {
    if(!obj) {
        fprintf(stderr, "\nERROR: Obj is null.\n");
        return;
    }
    obj->lua_event_cb = ref.ref;
}


void lv_lua_event_cb_caller(lv_obj_t * obj, lv_event_t event) {
    if (obj->lua_event_cb >= 0)  {
        lua_State *L = get_lua_state();
        if (!L) return;
    
        lua_rawgeti(L, LUA_REGISTRYINDEX, obj->lua_event_cb);

        SWIG_NewPointerObj(L, obj, SWIGTYPE_p__lv_obj_t, 0);
        lua_pushinteger(L, event);

        if (lua_pcall(L, 2, 0, 0)) {
            fprintf(stderr, "\nERROR: Error calling callback Lua function: %s\n\n", lua_tostring(L, -1));
            lua_pop(L, -1);
        }
    }
}

}