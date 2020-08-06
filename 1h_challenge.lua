#!/usr/bin/sblua
CHALLENGE_TIME=60*60; -- 1h (in seconds)
--CHALLENGE_TIME=1*60; -- 1m (for testing)

ride_distance="0m";

package.path="/etc/sblua/?.lua;/usr/share/sblua-5.2/?/init.lua;/usr/share/sblua-5.2/?.lua";
package.cpath="/usr/lib/sblua-5.2/?.so";

-- Dash2 project configuration
config=require("config");
dash=require("dash");

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

function start_ride()
  -- Send ride start event.
  send_ride_action_event(event_pb.RideAction.RIDE_START);
end

function end_ride()
  -- Send "End and save" menu item selected event
  local event = event_pb.UiSelectEvent();
  event.screen = resources.R_screen.ride_paused;
  event.selected = resources.R_action.save;
  send_event(push_socket, resources.R_event.ui_select, event);
  print("DEBUG: UiSelectEvent is sent.");

  lv.gauge_set_value(speedometer, 0, 0);
  lv.bar_set_value(progress, 0, lv.ANIM_OFF);

  create_msgbox(scr, g, "Your result:\n"..ride_distance, {"Great"}, end_msgbox_event_cb);

  lv.task_handler(); -- Update UI
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

function ui_data_event_handler(topic, protobuf_message)
  -- Decode message
  local msg = event_pb.UiDataEvent();
  msg:ParseFromString(protobuf_message);

  for key,update in ipairs(msg.update) do

    if update.metric == metric_pb.Metric.kMetricRideTime and update.span == metric_pb.Span.kSpanRide and update.operation == metric_pb.Operation.kOperationTotal
    then
      local ride_time = update.ivalue;
      -- print("DEBUG: Time (seconds): ", ride_time, ", span: ", update.span, ", operation:", update.operation);
      lv.bar_set_value(progress, ride_time, lv.ANIM_OFF);

      if ride_time >= CHALLENGE_TIME
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
end


function main()
  init_gui();
  init_protobuf();

  push_socket = init_nanomsg();
  send_hello_event(push_socket);

  local event_handlers = {
    [resources.R_event.keyboard] = keyboard_event_handler,
    [resources.R_event.ui_data] = ui_data_event_handler,
  };

  print "Entering event loop. Press ^C to stop program.";
  nanomsg_loop(event_handlers);
end

main();
