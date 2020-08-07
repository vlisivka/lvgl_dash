
-- Dash2 UI configuration
config=require("config");

-- LVGL
lv=require "lvgl";

-- Import protobuf definitions. Takes lot of CPU and bunch of memory.
function init_protobuf()
  -- nanomsg
  nanomsg = require("nanomsg");

  -- Protobuf stubs. Order is important.
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


  -- Map of keyboard codes from Dash to LVGL for keyboard handler
  dash_to_lvgl_button_map={
    [event_pb.Button.Forward]=lv.KEY_NEXT,
    [event_pb.Button.Backward]=lv.KEY_PREV,
    [event_pb.Button.LapBack]=lv.KEY_ESC,
    [event_pb.Button.Select]=lv.KEY_ENTER,
    [event_pb.Button.StartStop]=lv.KEY_DEL,
  };

  -- Map of keyboard actions from Dash to LVGL
  dash_to_lvgl_action_map={
    [event_pb.ButtonAction.Down]=lv.INDEV_STATE_PR,
    [event_pb.ButtonAction.Up]=lv.INDEV_STATE_REL,
    [event_pb.ButtonAction.LongPressUp]=lv.INDEV_STATE_REL,

    -- Long pess will act in same way as regular press,
    -- so it will be two quick presses in row, so it better
    -- to ignore long presses.
    -- [event_pb.ButtonAction.LongPressDown]=lv.INDEV_STATE_PR,
  };

end


-- Sends hello event to event server with screen and pid of this application
-- and returns nanomsg push socket for use in application. If socket is not
-- used, then it must be closed, to save resources.
function init_nanomsg()
  -- nanomsg
  nanomsg = require("nanomsg");

  -- Send hello message with screen and PID.
  local push_socket = nanomsg.socket(nanomsg.AP_SP, nanomsg.PUSH);
  local push_socket_ok, _ = push_socket:connect(config.NANOMSG_PULL_SOCKET_URL);
  assert(push_socket_ok, "Cannot connect to nanomsg Push URL.");

  return push_socket;
end

-- Add header and send given event using nanomsg socket.
function send_event(socket, topic, event)
  local data = event:SerializeToString();
  local len = string.len(data);
  
  -- Add header and send message using nanomsg
  local msg = string.char(topic, len % 256, len / 256) .. event:SerializeToString();
  return socket:send(msg);
end

-- Send Hello event with screen and pid of this application.
function send_hello_event(push_socket)
  local event = event_pb.Hello();

  -- Use name of the script file as name of service
  event.service_name = arg[0];
  -- Get screen index from environment variable
  event.screen = tonumber(os.getenv("SCREEN"));
  -- Get PID of this script
  event.pid = get_pid_of_self();

  assert(send_event(push_socket, resources.R_event.hello, event));
  -- Send Hello event twice, because first message can be lost due to bug in Nanomsg Pull/Push protocol.
  assert(send_event(push_socket, resources.R_event.hello, event));
end

-- Receive message from socket, parse header and return raw Protobuf message.
function receive_raw_message(socket)
  local msg = socket:recv_nb(8000);
  if not msg then
    -- Message not received (timeout, interrupt, an error)
    return 0;
  end

  local raw_message = {};
  -- Header
  raw_message.topic = string.byte(msg, 1);
  raw_message.len =  string.byte(msg, 3)*256 + string.byte(msg, 2);
  raw_message.protobuf_message = string.sub(msg, 4);

  assert(raw_message.len==string.len(raw_message.protobuf_message), "Unexpected length of message: declared length is not equal to actual length of Protobuf message.");
  return raw_message;
end


-- Default handler for keyboard events, which adapt Dash keyboard to LVGL.
function keyboard_event_handler(topic, protobuf_message)
  -- Decode message
  local event = event_pb.KeyboardEvent();
  event:ParseFromString(protobuf_message);
  --print("DEBUG: event.button:", event.button, "event.action:", event.action, "event.pid:", event.pid);

  if event.pid == pid then
    local key = dash_to_lvgl_button_map[event.button];
    local state = dash_to_lvgl_action_map[event.action];

    if key ~= nil and state ~= nil then
      lv.virt_keyboard_handler(key, state);
    else
      --print("Warning: Unknown key! Dash button:", event.button, ", LVGL key:", key, ", Dash action:", event.action, ", LVGL state:", state);
    end
  end
end


-- Continuously receive messages from GEH using Pub-Sub protocol and handle them.
function nanomsg_loop(handlers)
  -- Quickly perform update of GUI.
  lv.task_handler();

  -- Create socket
  local sub_socket = nanomsg.socket(nanomsg.AP_SP, nanomsg.SUB);

  -- Subscribe to topics
  for topic, handler in pairs(handlers) do
    assert(sub_socket:setopt(nanomsg.SUB, nanomsg.SUB_SUBSCRIBE, string.char(topic)));
  end

  local sub_socket_ok, _ = sub_socket:connect(config.NANOMSG_PUB_SOCKET_URL);
  assert(sub_socket_ok, "Cannot connect to nanomsg Sub URL.");

  -- Store PID in global variable for keyboard event handler.
  pid = get_pid_of_self();

  while (true) do
    local raw_message = NULL;
    repeat
      -- Update UI
      lv.task_handler();

      -- Try to receive message
      raw_message = receive_raw_message(sub_socket);
    until raw_message ~= 0;

    local handler=handlers[raw_message.topic];
    --print("DEBUG: Topic:", raw_message.topic, "handler: ", handler);
 
    if handler ~= nil then
      handler(topic, raw_message.protobuf_message);
    else
      print("ERROR: Handler is not set for topic: ", raw_message.topic);
    end

    lv.task_handler();
  end
end

-- Return PID of this process as number.
function get_pid_of_self()
  -- Read first number from /proc/self/stat file on Linux, which is the PID of the process.
  local pid = 0;
  local f = io.open("/proc/self/stat", "rb");
  if f then
    pid = f:read("*number");
    f:close();
  else
    -- MacOS? Windows?
    pid = 42;
  end

  return pid;
end

-- If focus changed via keyboard, then show focused object.
-- Function blindly assumes that parent page is able to do that.
function focus_cb(obj, event)
  if event == lv.EVENT_FOCUSED 
  then
    lv.page_focus(lv.obj_get_parent(obj), obj, lv.ANIM_ON);
  end
end
                                                             