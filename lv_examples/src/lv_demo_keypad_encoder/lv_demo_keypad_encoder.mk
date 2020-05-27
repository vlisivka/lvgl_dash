CSRCS += lv_demo_keypad_encoder.c

DEPPATH += --dep-path $(LVGL_DIR)/lv_examples/src/lv_demo_keypad_encoder
VPATH += :$(LVGL_DIR)/lv_examples/src/lv_demo_keypad_encoder
CFLAGS += "-I$(LVGL_DIR)/lv_examples/src/lv_demo_keypad_encoder"

