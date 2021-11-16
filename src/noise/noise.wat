;; CONWAY'S GAME OF LIFE

(module
  ;; IMPORTS
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  (import "noise" "noise_3d" (func $noise_3d (param f64 f64 f64) (result f64)))
  (import "console" "log" (func $log (param i32)))
  (import "console" "log" (func $log_float (param f64)))

  ;; MEMORY
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  (memory (export "memory") 9)
  (type $OneParameter (func (param i32))) 
  (table funcref (elem $update_cell $draw_cell))
  (global $UPDATE_CELL i32 (i32.const 0))
  (global $DRAW_CELL i32 (i32.const 1))

  ;; constant globals
  (global $WIDTH (export "WIDTH") i32 (i32.const 100))
  (global $HEIGHT (export "HEIGHT") i32 (i32.const 100))
  (global $NUM_CELLS (mut i32) (i32.const 0))
  (global $FADE_DECREMENT i32 (i32.const 1))
  (global $DIVIDE_COORDINATE_FACTOR f64 (f64.const 20)) ;; how gradual the noise appears
  (global $TIME_INCREMENT f64 (f64.const 0.0015))

  ;; cell data
  (global $CELL_MEMORY_OFFSET i32 (i32.const 0))
  (global $CELL_MEMORY_LENGTH (mut i32) (i32.const 0))
  (global $TIME (mut f64) (f64.const 0))

  ;; canvas data
  (global $BPP (export "BPP") i32 (i32.const 4)) ;; bytes per pixel
  (global $CANVAS_MEMORY_OFFSET (export "CANVAS_MEMORY_OFFSET") (mut i32) (i32.const 0))
  (global $CANVAS_MEMORY_LENGTH (export "CANVAS_MEMORY_LENGTH") (mut i32) (i32.const 0))
  

  ;; INIT GLOBALS 
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  (func $set_num_cells
    global.get $HEIGHT
    global.get $WIDTH
    i32.mul
    global.set $NUM_CELLS
  )
  (func $set_cell_memory_length
    global.get $WIDTH
    global.get $HEIGHT
    i32.mul
    global.set $CELL_MEMORY_LENGTH
  )
  (func $set_canvas_memory_offset
    global.get $CELL_MEMORY_OFFSET
    global.get $CELL_MEMORY_LENGTH
    i32.add
    global.set $CANVAS_MEMORY_OFFSET
  )
  (func $set_canvas_memory_length
    global.get $CELL_MEMORY_LENGTH
    global.get $BPP
    i32.mul
    global.set $CANVAS_MEMORY_LENGTH
  )

  ;; FUNCTIONS
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;; converts cell number to memory index of cell
  (func $cell_number_to_cell_mem_index (param $cell_number i32) (result i32)
    (i32.add 
      (local.get $cell_number)
      (global.get $CELL_MEMORY_OFFSET)
    )
  )

  ;; converts cell number to memory index of canvas cell pixel
  (func $cell_number_to_pixel_mem_index (param $cell_number i32) (result i32)
    (i32.add 
      (i32.mul
        (local.get $cell_number)
        (global.get $BPP)
      )
      (global.get $CANVAS_MEMORY_OFFSET)
    )
  )

   (func $set_cell_alive (param $cell_num i32)
    (i32.store8 (call $cell_number_to_cell_mem_index (local.get $cell_num)) (i32.const 255))
  )

  (func $get_x_coord_from_cell_num (param $cell_num i32) (result i32)
    (local.get $cell_num)
    (global.get $WIDTH)
    i32.rem_s
  )

  (func $get_y_coord_from_cell_num (param $cell_num i32) (result i32)
    (local.get $cell_num)
    (global.get $WIDTH)
    i32.div_s
  )

  (func $update_cell (param $cell_num i32)
    (local $cell_mem_index i32)
    (local $new_cell_value i32)
    (local $decremented_cell_value i32)

    (local.set $cell_mem_index (call $cell_number_to_cell_mem_index (local.get $cell_num)))

    (i32.store8 
      (local.get $cell_mem_index) 
      (i32.trunc_f64_s 
        (f64.mul
            (call $noise_3d
              (global.get $TIME)
              (f64.div 
                (f64.convert_i32_u 
                  (call $get_x_coord_from_cell_num (local.get $cell_num))
                )
                (global.get $DIVIDE_COORDINATE_FACTOR)
              )
              (f64.div 
                (f64.convert_i32_u 
                  (call $get_y_coord_from_cell_num (local.get $cell_num))
                )
                (global.get $DIVIDE_COORDINATE_FACTOR)
              )
            )
            (f64.const 256)
        )
      )
    )
  )

   ;; convert cell data into drawable pixels for the canvas
  (func $draw_cell (param $cell_num i32)
    (local $cell_mem_index i32)
    (local $pixel_mem_index i32)
    (local $cell_value i32)
    (local $r i32)
    (local $g i32)
    (local $b i32)

    ;; convert raw i to cell i & pixel i
    (local.set $cell_mem_index (call $cell_number_to_cell_mem_index (local.get $cell_num)))
    (local.set $pixel_mem_index (call $cell_number_to_pixel_mem_index (local.get $cell_num)))
    (local.set $cell_value (i32.load8_u (local.get $cell_mem_index)))

    ;; update canvas pixel data
    (i32.store8 (local.get $pixel_mem_index) (local.get $cell_value))
    (i32.store8 (i32.add (local.get $pixel_mem_index) (i32.const 1)) (local.get $cell_value))
    (i32.store8 (i32.add (local.get $pixel_mem_index) (i32.const 2)) (local.get $cell_value))
    (i32.store8 (i32.add (local.get $pixel_mem_index) (i32.const 3)) (i32.const 0xFF))
  )
 
  (func $iterate_through_cells (param $func_ref i32)
    (local $i i32)
    (local.set $i (i32.const 0))

    (loop $loop
      ;; perform indicated callback
      (call_indirect (type $OneParameter) (local.get $i) (local.get $func_ref))

      ;; loop until reaching the end of cells
      (if (i32.eq (local.get $i) (i32.sub (global.get $NUM_CELLS)) (i32.const 1))
        (then return)
        (else 
          (local.set $i (i32.add (local.get $i) (i32.const 1)))
          br $loop
        )
      )
    )
  )

  (func $increment_time
    (global.set $TIME (f64.add (global.get $TIME) (global.get $TIME_INCREMENT)))
  )

  ;; prepares state
  (func $init (export "init")
    ;; init globals
    (call $set_num_cells)
    (call $set_cell_memory_length)
    (call $set_canvas_memory_offset)
    (call $set_canvas_memory_length)
  )

  ;; update state on every tick
  (func $update (export "update")
    (call $increment_time)
    (call $iterate_through_cells (global.get $UPDATE_CELL))
    (call $iterate_through_cells (global.get $DRAW_CELL))
  )
)