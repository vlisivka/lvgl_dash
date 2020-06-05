#!/usr/bin/sblua

-- Initialization
lv = require "lvgl";
lv.init_app();
evdev_indev = lv.init_keyboard();

-- Widget group, for focus
g = lv.group_create();

-- Create controls --

-- Create tab view with two tabs
tv = lv.tabview_create(lv.scr_act(), NULL);
lv.group_add_obj(g, tv);

tab_tests = lv.tabview_add_tab(tv, "Tests");
lv.page_set_scrl_layout(tab_tests, lv.to_lv_layout_t(lv.LAYOUT_COLUMN_MID));

tab_logs = lv.tabview_add_tab(tv, "Logs");
lv.page_set_scrl_layout(tab_logs, lv.to_lv_layout_t(lv.LAYOUT_COLUMN_MID));

-- Add Test button to "Tests" tab
btn = lv.btn_create(tab_tests, NULL);
lv.group_add_obj(g, btn);
label =  lv.label_create(btn, NULL);
lv.label_set_text(label, "TODO");

-- Set group to be driven by keyboard
lv.indev_set_group(evdev_indev, g);

-- Set active by default element in group
lv.group_focus_obj(btn);

-- Callback for button
function todo_btn_cb(btn, event)
  if event == lv.EVENT_PRESSED
  then
    print("Hello, world!\n", btn);
  end
end

-- Bind callback to button
lv.obj_set_lua_event_cb(btn, todo_btn_cb);

print "Entering event loop. Press ^C to stop program.";
lv.event_loop();

