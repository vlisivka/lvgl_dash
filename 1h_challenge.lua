#!/usr/bin/sblua
CHALLENGE_TIME=60*60; -- 1h (in seconds)
--CHALLENGE_TIME=1*60; -- 1m (for testing)

ride_distance="0m";

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
        if update.metric == metric_pb.Metric.kMetricRideTime and update.span == metric_pb.Span.kSpanRide and update.operation == metric_pb.Operation.kOperationTotal
        then
          local ride_time = update.ivalue;
          -- print("DEBUG: Time (seconds): ", ride_time, ", span: ", update.span, ", operation:", update.operation);
          lv.bar_set_value(progress, ride_time, lv.ANIM_OFF);

          if ride_time == CHALLENGE_TIME
          then
            end_ride();
          end

        elseif update.metric == metric_pb.Metric.kMetricDistance and update.span == metric_pb.Span.kSpanRide and update.operation == metric_pb.Operation.kOperationTotal
        then
          local ride_distance_float = update.fvalue;
          ride_distance = string.format("%dm", ride_distance_float); -- TODO: Support imperial units
          -- print("DEBUG: Distance (metters): ", ride_distance, ", span: ", update.span, ", operation:", update.operation);
          lv.label_set_text(distance, ride_distance);

        elseif update.metric == metric_pb.Metric.kMetricSpeed and update.span == metric_pb.Span.kSpanInstant and update.operation == metric_pb.Operation.kOperationAverage
        then
          local ride_speed = update.fvalue;
          -- print("DEBUG: Speed (m/s): ", ride_speed, ", span: ", update.span, ", operation:", update.operation);
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

  push_socket = nanomsg.socket(nanomsg.AP_SP, nanomsg.PUSH);
  print('Trying to connect to "', config.NANOMSG_PULL_SOCKET_URL, '" using Push protocol.');
  local push_socket_ok, _ = push_socket:connect(config.NANOMSG_PULL_SOCKET_URL);
  assert(push_socket_ok, "Cannot connect to nanomsg Push URL.");
  print('Connected to "', config.NANOMSG_PULL_SOCKET_URL, '" using Push protocol.');
  
  local event = event_pb.Hello();
  event.service_name = "1h_challenge";
  assert(send_event(push_socket,resources.R_event.hello, event));
end

function create_msgbox(parent, group, text, buttons, cb)
    local mbox = lv.msgbox_create(parent, NULL);
    lv.msgbox_set_text(mbox, text);
    lv.obj_set_lua_event_cb(mbox, cb);
    lv.group_add_obj(group, mbox);
    lv.group_focus_obj(mbox);
    lv.group_set_editing(group, false);
    lv.group_focus_freeze(group, true);
    lv.obj_align(mbox, NULL, lv.ALIGN_CENTER, 0, 0);

-- Doesn't work, needs wrapper function to be implemented.
--    lv.msgbox_add_btns(mbox, buttons);

    lv.obj_set_style_local_bg_opa(lv.layer_top(), lv.OBJ_PART_MAIN, lv.STATE_DEFAULT, lv.OPA_30);
    lv.obj_set_style_local_bg_color(lv.layer_top(), lv.OBJ_PART_MAIN, lv.STATE_DEFAULT, lv.color_make(80,80,80));

    return mbox;
end

function welcome_msgbox_event_cb(msgbox, event)
    if(event == lv.EVENT_CLICKED)
    then
        lv.obj_del(msgbox);
        lv.event_send(lv.scr_act(), lv.EVENT_REFRESH, NULL);

        start_ride();
    end
end

function start_ride()
  -- Send ride start event.
  send_ride_action_event(event_pb.RideAction.RIDE_START);
end

function end_ride()
  -- Send ride end event.
--  send_ride_action_event(event_pb.RideAction.RIDE_END);

  -- Send "End and save" menu item selected event
  local event = event_pb.UiSelectEvent();
  event.screen = 196;
  event.selected = 192;
  event.selected_int = 519;
  local send_ok = send_event(push_socket, resources.R_event.ui_select, event);
  assert(send_ok);
  print("UiSelectEvent is sent.");

  lv.gauge_set_value(speedometer, 0, 0);
  lv.bar_set_value(progress, 0, lv.ANIM_OFF);

  create_msgbox(scr, g, "Your result:\n"..ride_distance, {"Great"}, end_msgbox_event_cb);

  lv.task_handler(); -- Update UI

end

function end_msgbox_event_cb(msgbox, event)
    if(event == lv.EVENT_CLICKED)
    then
        lv.obj_del(msgbox);
        lv.event_send(lv.scr_act(), lv.EVENT_REFRESH, NULL);

        os.exit();
    end
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
  lv.obj_align(progress, NULL, lv.ALIGN_IN_BOTTOM_MID, 0, -40);
  lv.bar_set_range(progress, 1, CHALLENGE_TIME); -- 1 hour in seconds
  lv.bar_set_type(progress, lv.BAR_TYPE_SYMMETRICAL);
  lv.bar_set_value(progress, 0, lv.ANIM_OFF);

  -- Create distance label
  distance = lv.label_create(scr, NULL);
  lv.label_set_recolor(distance, true);
  lv.obj_align(distance, NULL, lv.ALIGN_IN_BOTTOM_MID, 0, -90);
  lv.label_set_align(distance, lv.LABEL_ALIGN_CENTER);
  lv.label_set_text(distance, "0m");
  --lv.obj_add_style(distance, lv.LABEL_PART_MAIN, label_style);
  lv.obj_set_style_local_text_font(distance, lv.LABEL_PART_MAIN, lv.STATE_DEFAULT, lv.font_montserrat_24);
  
  -- Create message box
  create_msgbox(scr, g, "How far you can go in 1 Hour?", {"Start"}, welcome_msgbox_event_cb);

  lv.store_lua_state();

  lv.task_handler(); -- Update UI
end

function main()
  init_gui();
  init_nanomsg();

  print "Entering event loop. Press ^C to stop program.";
  nanomsg_loop();
end

main();
