#!/usr/bin/sblua

-- Initialization
lv = require "lvgl";
lv.init();
evdev_indev = lv.init_keyboard();

-- Widget group, for focus
g = lv.lv_group_create();

-- Create controls --

-- Create tab view with two tabs
tv = lv.lv_tabview_create(lv.lv_scr_act(), NULL);
lv.lv_group_add_obj(g, tv);

tab_tests = lv.lv_tabview_add_tab(tv, "Tests");
lv.lv_page_set_scrl_layout(tab_tests, lv.to_lv_layout_t(lv.LV_LAYOUT_COLUMN_MID));

tab_logs = lv.lv_tabview_add_tab(tv, "Logs");
lv.lv_page_set_scrl_layout(tab_logs, lv.to_lv_layout_t(lv.LV_LAYOUT_COLUMN_MID));

-- Add Test button to "Tests" tab
btn = lv.lv_btn_create(tab_tests, NULL);
lv.lv_group_add_obj(g, btn);
label =  lv.lv_label_create(btn, NULL);
lv.lv_label_set_text(label, "TODO");

-- Set group to be driven by keyboard
lv.lv_indev_set_group(evdev_indev, g);

-- Set active by default element in group
lv.lv_group_focus_obj(btn);

-- Callback for button
function todo_btn_cb(btn, event)
  if event == lv.LV_EVENT_PRESSED
  then
    print("Hello, world!\n", btn);
  end
end

-- Bind callback to button
lv.lv_obj_set_lua_event_cb(btn, todo_btn_cb);

print "Entering event loop. Press ^C to stop program.";
lv.event_loop();

