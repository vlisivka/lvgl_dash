#!/usr/bin/sblua
package.path="/etc/sblua/?.lua;/usr/share/sblua-5.2/?/init.lua;/usr/share/sblua-5.2/?.lua";
package.cpath="/usr/lib/sblua-5.2/?.so";

-- Dash2 project configuration
config=require("config");
dash=require("dash");

-- LIP: Lua Ini Parser
LIP = require "LIP";

-- Table of ini files read from /usr/share/applications
applications = {};

-- Return list of files in a directory, without recursion
function find_files(directory, extension)
    local pfile = assert(io.popen(("find '%s' -mindepth 1 -maxdepth 1 -type f -name '*%s' -print0"):format(directory, extension), 'r'));
    local list = pfile:read('*a');
    pfile:close();

    local files = {};

    -- Split zero-terminated strings into table
    for filename in string.gmatch(list, '[^%z]+') do
        table.insert(files, filename)
    end

    return files
end

function launch_list_event_handler(obj, event)
  --print("DEBUG: Event: ", event);

  if event == lv.EVENT_FOCUSED 
  then
    lv.page_focus(lv.object_get_parent(obj), obj, lv.ANIM_ON);
  end

  if event == lv.EVENT_PRESSED then
      local app_name = lv.list_get_btn_text(obj);
      -- print("DEBUG: Pressed: ", app_name);
      
      local app_ini = applications[app_name];
      local app_exe = app_ini['Desktop Entry']['Exec'];
      
      -- Execute application. Current app will be paused until app will exit.
      -- print("DEBUG: Launching: ", app_exe);
      os.execute(app_exe);

      -- Redraw screen
      lv.obj_invalidate(lv.scr_act());

      -- Grab keyboard input on this screen again
      send_hello_event(push_socket);
  end
end

function init_gui()
  lv.init_app();
  evdev_indev = lv.init_keyboard();

  -- Element group, for focus shift
  g = lv.group_create();

  -- Set group to be driven by keyboard
  lv.indev_set_group(evdev_indev, g);
  
  -- Create tab view with few tabs
  tv = lv.tabview_create(lv.scr_act(), NULL);
  lv.group_add_obj(g, tv);

  launch_tab = lv.tabview_add_tab(tv, "Launch");
  lv.page_set_scrl_layout(launch_tab, lv.LAYOUT_COLUMN_LEFT); -- Column aligned to left

  -- Create list of apps to launch --

  launch_list = lv.list_create(launch_tab, NULL);
  lv.obj_set_size(launch_list, 220, 240);
  lv.obj_align(launch_list, NULL, lv.ALIGN_CENTER, 0, 0);
  lv.group_add_obj(g, launch_list);

  local files = find_files("/usr/share/applications", ".desktop");
  for i=1, #files do
    local filename = files[i];
    local app_ini = LIP.load(filename);
    local app_name = app_ini['Desktop Entry']['GenericName'];
    applications[app_name] = app_ini;
    
    local list_btn = lv.list_add_btn(launch_list, NULL, app_name);
    lv.obj_set_lua_event_cb(list_btn, launch_list_event_handler);
  end

  lv.group_focus_obj(launch_list);
  lv.group_set_editing(g, true);

  -- Update UI once
  lv.store_lua_state();
  lv.task_handler(); 
end


function main()
  init_gui();
  init_protobuf();

  push_socket = init_nanomsg();
  send_hello_event(push_socket);

  local event_handlers = {
    [resources.R_event.keyboard] = keyboard_event_handler
  };

  print "Entering event loop. Press ^C to stop program.";
  nanomsg_loop(event_handlers);
end


main();
