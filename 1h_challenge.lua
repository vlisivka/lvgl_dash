#!/usr/bin/sblua
config=require("config");

-- Initialization
lv = require "lvgl";
-- nanomsg
nanomsg = require("nanomsg")
--require('luaunit')

-- Protobuf stubs
workout_pb = require("workout_pb") -- for event_pb.lua
metric_pb = require("metric_pb") -- for event_pb.lua
ant_pb = require("ant_pb") -- for event_pb.lua
ble_pb = require("ble_pb") -- for event_pb.lua
model_pb = require("model_pb") -- for event_pb.lua
icons_pb = require("icons_pb") -- for event_pb.lua
strings_pb = require("strings_pb") -- for event_pb.lua
event_pb = require("event_pb")
system_pb = require("system_pb")

-- Resources (event topics, strings, etc.)
resources = require("resources")

-- Add header and send given event using socket.
function send_event(socket, topic, event)
  local data = event:SerializeToString();
  local len = string.len(data);
  
  -- Add header and send message using nanomsg
  local msg = string.char(topic, len % 256, len / 256) .. event:SerializeToString();
  return socket:send(msg);
end

function init()
  sub_socket = nanomsg.socket(nanomsg.AP_SP, nanomsg.PUSH);

  print('Trying to connect to "', config.NANOMSG_SUB_SOCKET_URL, '" using Sub protocol.');
  local push_socket_ok, _ = push_socket:connect(config.NANOMSG_PUB_SOCKET_URL);
  assert(push_socket_ok, "Cannot connect to nanomsg Sub URL.");
  print('Connected to "', config.NANOMSG_SUB_SOCKET_URL, '" using Sub protocol.');

  push_socket = nanomsg.socket(nanomsg.AP_SP, nanomsg.PUSH);

  print('Trying to connect to "', config.NANOMSG_PULL_SOCKET_URL, '" using Push protocol.');
  local push_socket_ok, _ = push_socket:connect(config.NANOMSG_PULL_SOCKET_URL);
  assert(push_socket_ok, "Cannot connect to nanomsg Push URL.");
  print('Connected to "', config.NANOMSG_PULL_SOCKET_URL, '" using Push protocol.');
end

function teardown()
  print("Closing Pull socket.");
  push_socket:close();
  push_socket:shutdown();

  print("Closing Sub socket.");
  sub_socket:close();
  sub_socket:shutdown();
end

function write_to_file(text, file)
  local file = assert(io.open(file, "w"));
  file:write(text);
  file:close();
end

function create_button(parent, group, label, callback)
  -- Add Test button to "Tests" tab
  local btn = lv.btn_create(parent, NULL);
  lv.group_add_obj(group, btn);

  -- Bind callback to button
  lv.obj_set_lua_event_cb(btn, callback);

  local btn_label =  lv.label_create(btn, NULL);
  lv.label_set_text(btn_label, label);

  return btn;
end

function create_checkbox(parent, group, label, callback)
  -- Add Test button to "Tests" tab
  local cbx = lv.checkbox_create(parent, NULL);
  lv.group_add_obj(group, cbx);

  -- Bind callback to button
  lv.obj_set_lua_event_cb(cbx, callback);

  lv.checkbox_set_text(cbx, label);


  return cbx;
end


lv.init_app();
evdev_indev = lv.init_keyboard();

-- Element group, for focus shift
g = lv.group_create();

-- Set group to be driven by keyboard
lv.indev_set_group(evdev_indev, g);

-- Create controls --
scr = lv.scr_act();


-- Create style with bigger text for labels
label_style = lv.new_style();
lv.style_set_bg_color(label_style, lv.STATE_DEFAULT, lv.color_make(0,0,0));
lv.style_set_text_font(label_style, lv.STATE_DEFAULT, lv.font_montserrat_32);

-- Create header
header = lv.label_create(scr, NULL);
lv.label_set_recolor(header, true);
lv.obj_align(header, NULL, lv.ALIGN_IN_TOP_MID, -80, 5);
lv.label_set_align(header, lv.LABEL_ALIGN_CENTER);
lv.label_set_text(header, "#AAAA00 1h# #0000ff challenge#");
lv.obj_add_style(header, lv.LABEL_PART_MAIN, label_style);

-- Create speedometer
speedometer = lv.gauge_create(scr, NULL);
lv.group_add_obj(g, speedometer);
lv.obj_align(speedometer, NULL, lv.ALIGN_CENTER, 0, 0);
lv.obj_set_size(speedometer, 200, 120);
lv.gauge_set_scale(speedometer, 140, 10, 4);
lv.gauge_set_range(speedometer, 0, 60);
lv.gauge_set_critical_value(speedometer, 30)
lv.gauge_set_value(speedometer, 0, 0);

progress = lv.bar_create(scr, NULL);
lv.obj_set_size(progress, 200, 20);
lv.obj_align(progress, NULL, lv.ALIGN_IN_BOTTOM_MID, 0, -30);
lv.bar_set_range(progress, 1, 60);
lv.bar_set_type(progress, lv.BAR_TYPE_SYMMETRICAL);
lv.bar_set_value(progress, 0, lv.ANIM_OFF);

-- Create distance label
distance = lv.label_create(scr, NULL);
lv.label_set_recolor(distance, true);
lv.obj_align(distance, NULL, lv.ALIGN_IN_BOTTOM_MID, -80, -80);
lv.label_set_align(distance, lv.LABEL_ALIGN_CENTER);
lv.label_set_text(distance, "#00BB00 Distance:#   0km");
--lv.obj_add_style(distance, lv.LABEL_PART_MAIN, label_style);
lv.obj_set_style_local_text_font(distance, lv.LABEL_PART_MAIN, lv.STATE_DEFAULT, lv.font_montserrat_24);


print "Entering event loop. Press ^C to stop program.";
lv.event_loop();

