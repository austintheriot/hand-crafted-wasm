(module
  ;; IMPORTS
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  (import "noise" "perlin_noise" (func $perlin_noise (param f64 f64 f64) (result f64)))
  (import "Math" "sin" (func $sin (param f64) (result f64)))
  (import "Math" "cos" (func $cos (param f64) (result f64)))
  (global $PI (import "Math" "PI") f64)
  (import "console" "log" (func $log (param i32)))
  (import "console" "log" (func $log_float (param f64)))

  ;; MEMORY
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  (memory $memory (export "memory") 0)
  (type $ForEachCallback (func (param i32))) 
  (table funcref (elem $update_cell $draw_cell))
  (global $UPDATE_CELL i32 (i32.const 0))
  (global $DRAW_CELL i32 (i32.const 1))

  ;; constant globals
  (global $WIDTH (export "WIDTH") i32 (i32.const 500))
  (global $HEIGHT (export "HEIGHT") i32 (i32.const 500))
  (global $NUM_CELLS (mut i32) (i32.const 0))
  (global $DIVIDE_COORDINATE_FACTOR f64 (f64.const 30)) ;; how gradual the noise appears
  (global $FADE_DECREMENT i32 (i32.const 5))
  (global $CIRCLE_INCREMENT i32 (i32.const 150))
  (global $TIME_INCREMENT f64 (f64.const 0.009))

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
  ;; allocate memory based on necessary size of height and width arrays
  (func $set_memory
    (local $current_memory i32)
    (local $necessary_memory i32)
    (local $grow_memory i32)

    (local.set $current_memory (memory.size))

    (local.set $necessary_memory
      (i32.add
        (i32.div_s
        (i32.add
            (i32.mul
              (global.get $WIDTH)
              (global.get $HEIGHT)
            )
            (i32.mul
              (i32.mul
                (global.get $WIDTH)
                (global.get $HEIGHT)
              )
              (global.get $BPP)
            )
          )
          (i32.const 64_000)
        )
        (i32.const 1)
      )
    )

    (local.set $grow_memory
      (call $i32_max
        (i32.sub 
          (local.get $necessary_memory) 
          (local.get $current_memory)
        )
        (i32.const 0)
      )
    )

    (if (i32.gt_s (local.get $grow_memory) (i32.const 0))
      (then 
        (memory.grow (local.get $grow_memory))
        drop
      )
    )
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

  (func $get_cell_num_from_coords (param $x i32) (param $y i32) (result i32)
    ;; cell number = (y * width) + x
    global.get $WIDTH
    local.get $y
    i32.mul
    local.get $x
    i32.add
  )

  ;; get max between two i32 values
  (func $f64_max (param f64 f64) (result f64)
    (select
      (local.get 0)
      (local.get 1)
      (f64.gt (local.get 0) (local.get 1))
    )
  )

  ;; get min between two i32 values
  (func $f64_min (param f64 f64) (result f64)
    (select
      (local.get 0)
      (local.get 1)
      (f64.lt (local.get 0) (local.get 1))
    )
  )

  ;; get max between two i32 values
  (func $i32_max (param i32 i32) (result i32)
    (select
      (local.get 0)
      (local.get 1)
      (i32.gt_s (local.get 0) (local.get 1))
    )
  )

  ;; get min between two i32 values
  (func $i32_min (param i32 i32) (result i32)
    (select
      (local.get 0)
      (local.get 1)
      (i32.lt_s (local.get 0) (local.get 1))
    )
  )

  ;; clamp an i32 number between two other values 
  (func $f64_clamp (param $min f64) (param $num f64) (param $max f64) (result f64)
    (call $f64_min 
      (call $f64_max 
        (local.get $num) 
        (local.get $min)
      ) 
      (local.get $max)
    )
  )

  ;; map value from one range to another (and optionally clamp value at the end)
  (func $map (param $n f64) (param $start_min f64) (param $start_max f64) 
    (param $end_min f64) (param $end_max f64) (param $clamp i32) (result f64) 
    (local $new_val f64)

    (local.set $new_val
      (f64.add
        (f64.mul
          (f64.div
            (f64.sub
              (local.get $n)
              (local.get $start_min)
            )
            (f64.sub
              (local.get $start_max)
              (local.get $start_min)
            )
          )
          (f64.sub 
            (local.get $end_max)
            (local.get $end_min)
          )
        )
        (local.get $end_min)
      )
    )

    ;; optionally clamp value between the end min max
    (select 
      (call $f64_clamp (local.get $end_min) (local.get $new_val) (local.get $end_max))
      (local.get $new_val)
      (local.get $clamp)
    )
  )

  (func $update_circle (export "update_circle")
    (local $i f64)
    (local $angle f64)
    (local $radius f64)
    (local $TWO_PI f64)
    (local $SAMPLES f64)
    (local $x f64)
    (local $y f64)
    (local $TRANSLATE_X f64)
    (local $TRANSLATE_Y f64)
    (local $MIN_DIMENSION f64)
    (local $CIRCLE_BASE_RADIUS f64)
    (local $cell_number i32)
    (local $cell_mem_index i32)
    (local $current_cell_value i32)

    (local.set $SAMPLES (f64.const 200))
    (local.set $TRANSLATE_X 
      (f64.div 
        (f64.convert_i32_u (global.get $WIDTH))
        (f64.const 2)
      )
    )
    (local.set $TRANSLATE_Y
      (f64.div 
        (f64.convert_i32_u (global.get $HEIGHT))
        (f64.const 2)
      )
    )
    (local.set $TWO_PI (f64.mul (global.get $PI) (f64.const 2)))
    (local.set $MIN_DIMENSION
      (call $f64_min
        (f64.convert_i32_u (global.get $WIDTH))
        (f64.convert_i32_u (global.get $HEIGHT))
      )
    )
    (local.set $CIRCLE_BASE_RADIUS
      (f64.div
        (local.get $MIN_DIMENSION)
        (f64.const 2)
      )
    )

    (loop $loop
      ;; number points to sample around circle
      (if (f64.lt (local.get $i) (local.get $SAMPLES))
        (then
          (local.set $angle 
            (call $map 
              (local.get $i)
              (f64.const 0)
              (local.get $SAMPLES)
              (f64.const 0)
              (f64.mul (local.get $TWO_PI) (f64.const 1.01))
              (i32.const 0)
            )
          )

          (local.set $radius 
            (f64.mul
              (local.get $CIRCLE_BASE_RADIUS)
              (call $perlin_noise 
                (f64.mul
                  (local.get $i)
                  (f64.const 0.01)
                )
                (global.get $TIME)
                (f64.const 0)
              )
            )
          )

          (local.set $x
            (f64.add
              (f64.mul
                (local.get $radius)
                (call $cos (local.get $angle))
              )
              (local.get $TRANSLATE_X)
            )
          )

          (local.set $y
            (f64.add
              (f64.mul
                (local.get $radius)
                (call $sin (local.get $angle))
              )
              (local.get $TRANSLATE_Y)
            )
          )

          (local.set $cell_number
            (call $get_cell_num_from_coords
              (i32.trunc_sat_f64_u (local.get $x))
              (i32.trunc_sat_f64_u (local.get $y))
            )
          )

          (local.set $cell_mem_index
            (call $cell_number_to_cell_mem_index (local.get $cell_number))
          )

          (local.set $current_cell_value (i32.load8_u (local.get $cell_mem_index)))

          (i32.store 
            (local.get $cell_mem_index) 
            (call $i32_min 
              (i32.add (local.get $current_cell_value) (global.get $CIRCLE_INCREMENT))
              (i32.const 255)
            )
          )

          ;; continue loop
          (local.set $i (f64.add (local.get $i) (f64.const 1)))
          br $loop
        )
        (else return)
      )
    )
  )
  

  (func $update_cell (param $cell_num i32)
    (local $cell_mem_index i32)
    (local $cell_value i32)

    ;; convert cell_num to memory index of cell value
    (local.set $cell_mem_index (call $cell_number_to_cell_mem_index (local.get $cell_num)))
    (local.set $cell_value (i32.load8_u (local.get $cell_mem_index)))

    ;; decrease cell life
    (local.set $cell_value 
      (call $i32_max 
        (i32.sub 
          (local.get $cell_value) 
          (global.get $FADE_DECREMENT)
        ) 
        (i32.const 0)
      )
    )

    ;; set life state of the current actual cell
    (i32.store8 (local.get $cell_mem_index) (local.get $cell_value))
  )

   ;; convert cell data into drawable pixels for the canvas
  (func $draw_cell (param $cell_num i32)
    (local $cell_mem_index i32)
    (local $pixel_mem_index i32)
    (local $cell_value i32)
    (local $r i32)
    (local $g i32)
    (local $b i32)

    ;; convert cell_num to memory index of cell and pixel
    (local.set $cell_mem_index (call $cell_number_to_cell_mem_index (local.get $cell_num)))
    (local.set $pixel_mem_index (call $cell_number_to_pixel_mem_index (local.get $cell_num)))
    (local.set $cell_value (i32.load8_u (local.get $cell_mem_index)))

    ;; update canvas pixel data - draw live circle as black and dead ones as black
    (i32.store8 (local.get $pixel_mem_index) (i32.sub (i32.const 255) (local.get $cell_value)))
    (i32.store8 (i32.add (local.get $pixel_mem_index) (i32.const 1)) (i32.sub (i32.const 255) (local.get $cell_value)))
    (i32.store8 (i32.add (local.get $pixel_mem_index) (i32.const 2)) (i32.sub (i32.const 255) (local.get $cell_value)))
    (i32.store8 (i32.add (local.get $pixel_mem_index) (i32.const 3)) (i32.const 0xFF))
  )

  ;; iterate through every pixel up to LENGTH and call given function
  (func $for_each (param $func_ref i32)
    (local $i i32)
    (loop $loop
      ;; loop until reaching the end of cells
      (if (i32.lt_s (local.get $i) (global.get $NUM_CELLS))
        (then
          ;; perform indicated callback
          (call_indirect (type $ForEachCallback) (local.get $i) (local.get $func_ref))
          (local.set $i (i32.add (local.get $i) (i32.const 1)))
          br $loop
        )
        (else return)
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
    (call $set_memory)
  )

  ;; update state on every tick
  (func $update (export "update")
    (call $increment_time)
    (call $for_each (global.get $UPDATE_CELL))
    (call $update_circle)
    (call $for_each (global.get $DRAW_CELL))
  )
)