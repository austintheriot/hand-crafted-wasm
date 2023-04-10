
export enum MainToWorkerMessageTypes {
    INIT = 'init',
    TICK = 'tick',
    SYNC_VIEWPORT = 'sync_viewport',
    HANDLE_TOUCH_MOVE = 'handle_touch_move',
    HANDLE_MOUSE_MOVE = 'handle_mouse_move',
    HANDLE_KEY = 'handle_key',
    HANDLE_BLUR = 'handle_blur',
    HANDLE_MOUSE_UP = 'handle_mouse_up',
    HANDLE_TOUCH_END = 'handle_touch_end',
  }

export enum WorkerToMainMessageTypes {
    INIT_DONE = 'init_done',
    TICK_DONE = 'tick_done',
    SYNC_VIEWPORT_DONE = 'sync_viewport_done',
    HANDLE_TOUCH_MOVE_DONE = 'handle_touch_move_done',
    HANDLE_MOUSE_MOVE_DONE = 'handle_mouse_move_done',
    HANDLE_KEY_DONE = 'handle_key_done',
    HANDLE_BLUR_DONE = 'handle_blur_done',
    HANDLE_MOUSE_UP_DONE = 'handle_mouse_up_done',
    HANDLE_TOUCH_END_DONE = 'handle_touch_end_done',
}