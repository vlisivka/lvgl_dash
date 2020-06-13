#!/usr/bin/sblua
CHALLENGE_TIME=60*60; -- 1h (in seconds)
--CHALLENGE_TIME=1*60; -- 1m (for testing)

-- Dash2 project configuration
config=require("config");

-- LVGL
lv = require "lvgl";


-- Add header and send given event using socket.
function send_event(socket, topic, event)
  local data = event:SerializeToString();
  local len = string.len(data);
  
  -- Add header and send message using nanomsg
  local msg = string.char(topic, len % 256, len / 256) .. event:SerializeToString();
  return socket:send(msg);
end

function send_keyboard_event(button, action)
  local event = event_pb.KeyboardEvent();
  event.button = button;
  event.action = action;
  local send_ok = send_event(push_socket, resources.R_event.keyboard, event);
  assert(send_ok, "Cannot send event to event-server.");
  print("Keyboard action is sent: button: "..button..", action: "..action..".");
end

-- Example: send_ride_action_event(event_pb.RideAction.RIDE_AUTO_RESUME)
function send_ride_action_event(action)
  local event = event_pb.RideActionEvent();
  event.action = action;

  local send_ok = send_event(push_socket, resources.R_event.ride_action, event);
  assert(send_ok);
  print("Ride action event is sent. Action: "..action..".");
end

-- Receive message from socket, parse header and return raw Protobuf message.
function receive_raw_message(socket)
  local msg = socket:recv_nb(8000);
  if not msg then
    -- Message not received (timeout, interrupt, an error)
    return 0
  end

  local raw_message = {};
  -- Header
  raw_message.topic = string.byte(msg, 1);
  raw_message.len =  string.byte(msg, 3)*256 + string.byte(msg, 2);
  raw_message.protobuf_message = string.sub(msg, 4);

  assert(raw_message.len==string.len(raw_message.protobuf_message), "Unexpected length of message: declared length is not equal to actual length of Protobuf message.");
  return raw_message;
end

-- Continuously receive messages from GEH using Pub-Sub protocol and print them out.
-- Subscribe to some messages only.
function nanomsg_loop()
  lv.task_handler();
  local sub_socket = nanomsg.socket(nanomsg.AP_SP, nanomsg.SUB);
  -- Subsscribe to event
  assert(sub_socket:setopt(nanomsg.SUB, nanomsg.SUB_SUBSCRIBE, string.char(resources.R_event.ui_data)));
  
  
  local sub_socket_ok, _ = sub_socket:connect(config.NANOMSG_PUB_SOCKET_URL);
  assert(sub_socket_ok, "Cannot connect to nanomsg Sub URL.");
  print('Connected to "'..config.NANOMSG_PUB_SOCKET_URL..'" using Sub protocol. Listening for message broadcasts.');

  while (true) do
    local raw_message = NULL;
    repeat
      -- Update UI
      lv.task_handler();

      -- Try to receive message
      raw_message = receive_raw_message(sub_socket);
    until raw_message ~= 0;

    if raw_message.topic == resources.R_event.ui_data then
      -- Decode message
      local msg = event_pb.UiDataEvent();
      msg:ParseFromString(raw_message.protobuf_message);

      for key,update in ipairs(msg.update) do
        if update.metric == metric_pb.Metric.kMetricRideTime
        then
          local ride_time = update.ivalue;
          print("DEBUG: Time (seconds): ", ride_time);
          lv.bar_set_value(progress, ride_time, lv.ANIM_OFF);

          if ride_time == CHALLENGE_TIME
          then
            end_ride();
          end

        elseif update.metric == metric_pb.Metric.kMetricDistance
        then
          local ride_distance = update.fvalue;
          print("DEBUG: Distance (metters): ", ride_distance);
          lv.label_set_text(distance, string.format("%dm", (ride_distance)));

        elseif update.metric == metric_pb.Metric.kMetricSpeed
        then
          local ride_speed = update.fvalue;
          print("DEBUG: Speed (m/s): ", ride_speed);
          lv.gauge_set_value(speedometer, 0, ride_speed*3.6); -- km/h
        end
      end

    else
      print("ERROR: Unknown topic of message: ", topic);
    end
    lv.task_handler();
  end
end


function init_nanomsg()
  -- nanomsg
  nanomsg = require("nanomsg");

  -- Protobuf stubs
  workout_pb = require("workout_pb"); -- for event_pb.lua
  metric_pb = require("metric_pb"); -- for event_pb.lua
  ant_pb = require("ant_pb"); -- for event_pb.lua
  ble_pb = require("ble_pb"); -- for event_pb.lua
  model_pb = require("model_pb"); -- for event_pb.lua
  icons_pb = require("icons_pb"); -- for event_pb.lua
  strings_pb = require("strings_pb"); -- for event_pb.lua
  event_pb = require("event_pb");
  system_pb = require("system_pb");

  -- Resources (event topics, strings, etc.)
  resources = require("resources");

  sub_socket = nanomsg.socket(nanomsg.AP_SP, nanomsg.SUB);
  print('Trying to connect to "', config.NANOMSG_SUB_SOCKET_URL, '" using Sub protocol.');
  local sub_socket_ok, _ = sub_socket:connect(config.NANOMSG_PUB_SOCKET_URL);
  assert(sub_socket_ok, "Cannot connect to nanomsg Sub URL.");
  print('Connected to "', config.NANOMSG_SUB_SOCKET_URL, '" using Sub protocol.');

  push_socket = nanomsg.socket(nanomsg.AP_SP, nanomsg.PUSH);
  print('Trying to connect to "', config.NANOMSG_PULL_SOCKET_URL, '" using Push protocol.');
  local push_socket_ok, _ = push_socket:connect(config.NANOMSG_PULL_SOCKET_URL);
  assert(push_socket_ok, "Cannot connect to nanomsg Push URL.");
  print('Connected to "', config.NANOMSG_PULL_SOCKET_URL, '" using Push protocol.');
  
  local event = event_pb.Hello();
  event.service_name = "1h_challenge";
  assert(send_event(push_socket,resources.R_event.hello, event));
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

function start_ride()
  -- Send ride start event.
  send_ride_action_event(event_pb.RideAction.RIDE_START);
end

function end_ride()
  -- Send ride end event.
  send_ride_action_event(event_pb.RideAction.RIDE_END);
  lv.gauge_set_value(speedometer, 0, 0);
  lv.bar_set_value(progress, 0, lv.ANIM_OFF);
  lv.task_handler(); -- Update UI

  os.exit();
end

function init_gui()
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
  lv.bar_set_range(progress, 1, CHALLENGE_TIME); -- 1 hour in seconds
  lv.bar_set_type(progress, lv.BAR_TYPE_SYMMETRICAL);
  lv.bar_set_value(progress, 0, lv.ANIM_OFF);

  -- Create distance label
  distance = lv.label_create(scr, NULL);
  lv.label_set_recolor(distance, true);
  lv.obj_align(distance, NULL, lv.ALIGN_IN_BOTTOM_MID, 0, -80);
  lv.label_set_align(distance, lv.LABEL_ALIGN_CENTER);
  lv.label_set_text(distance, "0m");
  --lv.obj_add_style(distance, lv.LABEL_PART_MAIN, label_style);
  lv.obj_set_style_local_text_font(distance, lv.LABEL_PART_MAIN, lv.STATE_DEFAULT, lv.font_montserrat_24);

  lv.store_lua_state();

  lv.task_handler(); -- Update UI
end

function main()
  init_gui();
  init_nanomsg();

  start_ride();

  print "Entering event loop. Press ^C to stop program.";
  nanomsg_loop();
end

main();
