#!/usr/bin/sblua
processes = { "ui", "event-server", "rfcom", "analytics", "behavior_tree", "map", "workout", "fitlog", "usbmgr" };

function is_logging_enabled(service)
  -- Look for 'export REDIRECT_LOGS_ENABLE="yes"'
  local file_name = "/etc/default/"..service;
  local found = false;
  local input = assert(io.open(file_name, "r"), "Cannot open file \""..file_name.."\" for reading.");
  local lines = "";
  while(true) do
    local line = input:read("*line");
    if not line then break; end -- End of content

    if string.find(line, "export REDIRECT_LOGS_ENABLE=\"yes\"", 1) == 1 then
      found = true;
    end
  end
  input:close()

  return found;
end

function set_logging(service, enabled)
  -- Look for 'export REDIRECT_LOGS_ENABLE="yes"'
  local file_name = "/etc/default/"..service;
  local found = false;
  local input = assert(io.open(file_name, "r"), "Cannot open file \""..file_name.."\" for reading.");
  local lines = "";

  while(true) do
    local line = input:read("*line");
    if not line then break; end -- End of content

    -- If statement is found (e.g. commented out)
    if string.find(line, "export REDIRECT_LOGS_ENABLE=\"yes\"", 1) then
      if enabled then
        lines = lines .. "export REDIRECT_LOGS_ENABLE=\"yes\"\n";
      end
      found = true;
    else
      lines = lines .. line .. "\n";
    end
  end
  input:close();

  if enabled and not found then
      lines = lines .. "export REDIRECT_LOGS_ENABLE=\"yes\"\n";
  end
  
  local output = assert(io.open(file_name, "w"), "Cannot open file \""..file_name.."\" for writing.");
  output:write(lines);
  output:close();
end

function process_log_checkbox_cb(checkbox, event)
  if event == lv.LV_EVENT_VALUE_CHANGED
  then
    local service = lv.lv_checkbox_get_text(checkbox);
    local checked = lv.lv_checkbox_is_checked(checkbox);

    --print("DEBUG: Checkbox for "..service.." is checked? "..tostring(checked));

    set_logging(service, checked);
  end
end


-- GUI --

-- Initialization
lv = require "lvgl";
lv.init();
evdev_indev = lv.init_keyboard();

-- Element group, for focus shift
g = lv.lv_group_create();

-- Set group to be driven by keyboard
lv.lv_indev_set_group(evdev_indev, g);


-- Create controls --

-- Create tab view with two tabs
tv = lv.lv_tabview_create(lv.lv_scr_act(), NULL);
lv.lv_group_add_obj(g, tv);

tab_logs = lv.lv_tabview_add_tab(tv, "Logs");
lv.lv_page_set_scrl_layout(tab_logs, lv.to_lv_layout_t(lv.LV_LAYOUT_COLUMN_LEFT)); -- Column aligned to left

tab_procs = lv.lv_tabview_add_tab(tv, "Proces");
lv.lv_page_set_scrl_layout(tab_procs, lv.to_lv_layout_t(lv.LV_LAYOUT_COLUMN_MID)); -- Centered column

function create_checkbox(parent, group, label, checked, callback)
  -- Add Test button to "Tests" tab
  local cbx = lv.lv_checkbox_create(parent, NULL);
  lv.lv_group_add_obj(group, cbx);

  -- Bind callback to button
  lv.lv_obj_set_lua_event_cb(cbx, callback);

  lv.lv_checkbox_set_text(cbx, label);
  
  lv.lv_checkbox_set_checked(cbx, checked);

  return cbx;
end

checkboxes = {};
for i,p in ipairs(processes) do
  checkboxes[i]=create_checkbox(tab_logs, g, p, is_logging_enabled(p), process_log_checkbox_cb);
end

-- Set first checkbox active by default
lv.lv_group_focus_obj(checkboxes[1]);

print "Entering event loop. Press ^C to stop program.";
lv.event_loop();
