(module
  ;; IMPORTS
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  (import "Math" "sqrt" (func $sqrt (param f64) (result f64)))
  (import "Math" "cbrt" (func $cbrt (param f64) (result f64)))
  (import "Math" "sin" (func $sin (param f64) (result f64)))
  (import "Math" "cos" (func $cos (param f64) (result f64)))
  (import "noise" "perlin_noise" (func $perlin_noise (param f64) (param f64) (param f64) (result f64)))
  (import "console" "log" (func $log (param i32)))
  (import "console" "log" (func $log_float (param f64)))

  ;; MEMORY
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  (memory $memory (export "memory") 2000)

  ;; function tables
  (type $ForEachCallback (func (param i32))) 
  (table funcref (elem $update_vertex_offsets $connect_vertex))
  (global $UPDATE_VERTEX i32 (i32.const 0))
  (global $CONNECT_VERTEX i32 (i32.const 1))

  ;; canvas data (no memory offset)
  (global $WIDTH (export "WIDTH") i32 (i32.const 400))
  (global $HEIGHT (export "HEIGHT") i32 (i32.const 400))
  (global $DEPTH i32 (i32.const 400))
  (global $VIEW_DISTANCE f64 (f64.const 1))
  (global $DT f64 (f64.const 0.01))
  (global $X_THETA (mut f64) (f64.const -0.5))
  (global $HEIGHT_DAMPING (mut f64) (f64.const 0.5))
  (global $DETAIL_MULTIPLIER (mut f64) (f64.const 2))
  (global $SCALE_X (mut f64) (f64.const 0.75))
  (global $TRANSLATE_Y (mut f64) (f64.const 0.25))
  (global $SCALE_Z (mut f64) (f64.const 0.25))
  (global $TIME (mut f64) (f64.const 0))
  (global $TIME_INCREMENT (mut f64) (f64.const 0.01))
  (global $NUM_PIXELS (mut i32) (i32.const 0))
  (global $BYTES_PER_PX i32 (i32.const 4))
  (global $MEM_NOP i32 (i32.const -1))
  (global $CANVAS_MEMORY_OFFSET (export "CANVAS_MEMORY_OFFSET") i32 (i32.const 0)) 
  (global $CANVAS_MEMORY_LENGTH (export "CANVAS_MEMORY_LENGTH") (mut i32) (i32.const 0))

  ;; vertex data (after canvas data)
  (global $INITIAL_PX_BETWEEN_VERTICES (mut i32) (i32.const 0))
  (global $NUM_VERTICES_SQRT i32 (i32.const 100))
  (global $NUM_VERTICES (mut i32) (i32.const 0))
  ;; bytes per vertex (x, y, z) => (f64, f64, f64) => (8 bytes, 8 bytes, 8 bytes) => 24 bytes 
  (global $BYTES_PER_VERTEX i32 (i32.const 24))
  (global $VERTEX_MEMORY_OFFSET (mut i32) (i32.const 0))
  (global $VERTEX_MEMORY_LENGTH (mut i32) (i32.const 0))


  ;; INTERNAL FUNCTIONS
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

   ;; clamp an f64 number between two other values 
  (func $f64_clamp (param $min f64) (param $num f64) (param $max f64) (result f64)
    (call $f64_min 
      (call $f64_max 
        (local.get $num) 
        (local.get $min)
      ) 
      (local.get $max)
    )
  )

  ;; get max between two f64 values
  (func $f64_max (param f64 f64) (result f64)
    (select
      (local.get 0)
      (local.get 1)
      (f64.gt (local.get 0) (local.get 1))
    )
  )

  ;; get min between two f64 values
  (func $f64_min (param f64 f64) (result f64)
    (select
      (local.get 0)
      (local.get 1)
      (f64.lt (local.get 0) (local.get 1))
    )
  )

  ;; map value from one range to another (and optionally clamp value at the end)
  (func $map (param $n f64) (param $start_min f64) (param $start_max f64) 
    (param $end_min f64) (param $end_max f64) (result f64) 
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

    (local.get $new_val)
  )

  (func $vertex_num_to_mem_location (param $i i32) (result i32)
    (i32.add 
      (global.get $VERTEX_MEMORY_OFFSET)
      (i32.mul
        (global.get $BYTES_PER_VERTEX)
        (local.get $i)
      )
    )
  )

 (func $init_vertices
    (local $vertex_mem_location i32)
    (local $x f64)
    (local $z f64)
    (local $width_float f64)
    (local $depth_float f64)
    (local $initial_px_between_vertices_float f64)
    (local $vertex_num i32)

    (local.set $width_float (f64.convert_i32_u (global.get $WIDTH)))
    (local.set $depth_float (f64.convert_i32_u (global.get $DEPTH)))
    (local.set $initial_px_between_vertices_float (f64.convert_i32_u (global.get $INITIAL_PX_BETWEEN_VERTICES)))
    (local.set $vertex_mem_location
      (call $vertex_num_to_mem_location
        (local.get $vertex_num)
      )
    )

    ;; iterate through z
    (loop $loop_z
      (if (f64.lt (local.get $z) (local.get $depth_float))
        (then

          ;; iterate through x
          (local.set $x (f64.const 0))
          (loop $loop_x
            (if (f64.lt (local.get $x) (local.get $width_float))
              (then

                ;; set vertices
                (f64.store 
                  offset=0
                  (local.get $vertex_mem_location)
                  (call $map
                    (local.get $x)
                    (f64.const 0)
                    (local.get $width_float)
                    (f64.const -1)
                    (f64.const 1)
                  )
                )
                (f64.store 
                  offset=8
                  (local.get $vertex_mem_location)
                  (f64.const 0)
                )
                (f64.store 
                  offset=16
                  (local.get $vertex_mem_location)
                  (call $map
                    (local.get $z)
                    (f64.const 0)
                    (local.get $depth_float)
                    (f64.const -1)
                    (f64.const 1)
                  )
                )

                (local.set $vertex_num (i32.add (local.get $vertex_num) (i32.const 1)))
                (local.set $vertex_mem_location
                  (call $vertex_num_to_mem_location
                    (local.get $vertex_num)
                  )
                )

                (local.set $x (f64.add (local.get $x) (local.get $initial_px_between_vertices_float)))
                br $loop_x
              )
            )
          )

          (local.set $z (f64.add (local.get $z) (local.get $initial_px_between_vertices_float)))
          br $loop_z
        )
      )
    )

  )

  (func $update_vertex_offsets (param $vertex_num i32)
    (local $vertex_mem_location i32)
    (local $vertex_num_as_float f64)
    (local $x f64)
    (local $z f64)

    ;; load vertex data
    (local.set $vertex_mem_location (call $vertex_num_to_mem_location (local.get $vertex_num)))
    (local.set $x 
      (f64.mul
        (f64.add 
          (f64.load offset=0 (local.get $vertex_mem_location))
          (f64.const 100)
        )
        (global.get $DETAIL_MULTIPLIER)
      )
    )
    (local.set $z 
      (f64.mul
        (f64.sub
          (f64.load offset=16 (local.get $vertex_mem_location))
          (global.get $TIME)
        )
        (global.get $DETAIL_MULTIPLIER)
      )
    )

    ;; update the y value to be different
    (f64.store offset=8
      (local.get $vertex_mem_location)
      (f64.mul
        (f64.sub
          (call $perlin_noise (local.get $x) (local.get $z) (f64.const 0))
          (f64.const 0.5)
        )
        (global.get $HEIGHT_DAMPING)
      )
    )
  )

  (func $canvas_coords_to_canvas_mem_index (param $x i32) (param $y i32) (result i32)
    ;; check if vertex is out of bounds
    (if (i32.or
        (i32.or
          (i32.lt_s
            (local.get $x)
            (i32.const 0)
          )
          (i32.gt_s
            (local.get $x)
            (i32.sub (global.get $WIDTH) (i32.const 1))
          )
        )
        (i32.or
          (i32.lt_s
            (local.get $y)
            (i32.const 0)
          )
          (i32.gt_s
            (local.get $y)
            (i32.sub (global.get $HEIGHT) (i32.const 1))
          )
        )
      )
      ;; nooop
      (then (return (global.get $MEM_NOP)))
    )

    ;; ignore z-index for now
    global.get $WIDTH
    local.get $y
    i32.mul
    local.get $x
    i32.add
    global.get $BYTES_PER_PX
    i32.mul
  )

  ;; get min between two i32 values
  (func $i32_min (param i32 i32) (result i32)
    (select
      (local.get 0)
      (local.get 1)
      (i32.lt_s (local.get 0) (local.get 1))
    )
  )

  ;; set canvas color as opaque black
  (func $clear_canvas
    (local $i i32)
    (local $end_i i32)
    (local.set $i 
      (global.get $CANVAS_MEMORY_OFFSET)
    )
    (local.set $end_i 
      (i32.add 
        (global.get $CANVAS_MEMORY_OFFSET) 
        (global.get $CANVAS_MEMORY_LENGTH)
      )
    )
    (loop $loop
      (if (i32.lt_s (local.get $i) (local.get $end_i))
        (then

          (i32.store8
            offset=0
            (local.get $i)
            (i32.const 0)
          )
          (i32.store8
            offset=1
            (local.get $i)
            (i32.const 0)
          )
          (i32.store8
            offset=2
            (local.get $i)
            (i32.const 0)
          )
          (i32.store8
            offset=3
            (local.get $i)
            (i32.const 0xff)
          )

          (local.set $i (i32.add (local.get $i) (global.get $BYTES_PER_PX)))
          br $loop
        )
        (else return)
      )
    )
  )

  (func $draw_pixel (param $x i32) (param $y i32)
    (param $r i32) (param $g i32) (param $b i32) (param $a i32)
    (local $canvas_mem_index i32)
    (local $canvas_mem_value i32)

    (local.set $canvas_mem_index 
      (call $canvas_coords_to_canvas_mem_index 
        (local.get $x)
        (local.get $y)
      )
    )

    ;; ignore coordinates that fall outside of (-1, 1) range
    (if (i32.eq (local.get $canvas_mem_index) (global.get $MEM_NOP))
      (then return)
    )

    (local.set $canvas_mem_value
      (i32.load8_u 
        (local.get $canvas_mem_index)
      ) 
    )

    ;; add colors from previous pixels together (max out at 0xff for each color band)
    (i32.store8
      offset=0
      (local.get $canvas_mem_index)
      (call $i32_min
        (i32.add 
          (local.get $canvas_mem_value) 
          (local.get $r)
        )
        (i32.const 0xff)
      )
    )
    (i32.store8
      offset=1
      (local.get $canvas_mem_index)
      (call $i32_min
        (i32.add 
          (local.get $canvas_mem_value) 
          (local.get $g)
        )
        (i32.const 0xff)
      )
    )
    (i32.store8
      offset=2
      (local.get $canvas_mem_index)
      (call $i32_min
        (i32.add 
          (local.get $canvas_mem_value) 
          (local.get $b)
        )
        (i32.const 0xff)
      )
    )
    (i32.store8
      offset=3
      (local.get $canvas_mem_index)
      (call $i32_min
        (i32.add 
          (local.get $canvas_mem_value) 
          (local.get $a)
        )
        (i32.const 0xff)
      )
    )
  )

  ;; use bit hacks to quickly get absolute value of i32
  (func $abs (param $value i32) (result i32)
    (local $temp i32)

    ;; make a mask of the sign bit
    (local.set $temp 
      (i32.shr_s 
        (local.get $value) 
        (i32.const 31)
      )
    )
    ;; toggle the bits if value is negative
    (local.set $value
      (i32.xor
        (local.get $value)
        (local.get $temp)
      )
    )
    ;; add one if value was negative
    (local.set $value
      (i32.add
        (local.get $value)
        (i32.and
          (local.get $temp)
          (i32.const 1)
        )
      )
    )

    (local.get $value)
  )

  ;; Bresenham's line algorithm
  (func $draw_line 
    (param $x0 i32) (param $y0 i32) (param $x1 i32) (param $y1 i32)
    (param $r i32) (param $g i32) (param $b i32) (param $a i32)
    (local $dx i32)
    (local $sx i32)
    (local $dy i32)
    (local $sy i32)
    (local $err i32)
    (local $e2 i32)

    (local.set $dx 
      (call $abs
        (i32.sub
          (local.get $x1)
          (local.get $x0)
        )
      )
    )

    (local.set $sx
      (select
        (i32.const 1)
        (i32.const -1)
        (i32.lt_s 
          (local.get $x0)
          (local.get $x1)
        )
      ) 
    )

    (local.set $dy
      (i32.mul
        (call $abs
          (i32.sub
            (local.get $y1)
            (local.get $y0)
          )
        )
        (i32.const -1)
      )
    )

    (local.set $sy
      (select
        (i32.const 1)
        (i32.const -1)
        (i32.lt_s
          (local.get $y0)
          (local.get $y1)
        )
      ) 
    )

    (local.set $err
      (i32.add
        (local.get $dx)
        (local.get $dy)
      )
    )

    (loop $loop
      (call $draw_pixel
        (local.get $x0)
        (local.get $y0)
        (local.get $r)
        (local.get $g)
        (local.get $b)
        (local.get $a)
      )
      (if 
        (i32.and
          (i32.eq
            (local.get $x0)
            (local.get $x1)
          )
          (i32.eq
            (local.get $y0)
            (local.get $y1)
          )
        )
        (then return)
      )

      (local.set $e2
        (i32.mul
          (i32.const 2)
          (local.get $err)
        )
      )

      (if 
        (i32.ge_s
          (local.get $e2)
          (local.get $dy)
        )
        (then
          (local.set $err
            (i32.add
              (local.get $err)
              (local.get $dy)
            )
          )
          (local.set $x0
            (i32.add
              (local.get $x0)
              (local.get $sx)
            )
          )
        )
      )

      (if 
        (i32.le_s
          (local.get $e2)
          (local.get $dx)
        )
        (then
          (local.set $err
            (i32.add
              (local.get $err)
              (local.get $dx)
            )
          )
          (local.set $y0
            (i32.add
              (local.get $y0)
              (local.get $sy)
            )
          )
        )
      )

      (br $loop)
    )
  )

  (func $get_vertex_in_screen_coords (param $vertex_num i32) (result i32 i32)
    (local $vertex_mem_location i32)
    (local $x f64)
    (local $y f64)
    (local $z f64)
    (local $temp2_x f64)
    (local $temp2_y f64)
    (local $temp2_z f64)
    (local $perspective_denominator f64)

    (local.set $vertex_mem_location (call $vertex_num_to_mem_location (local.get $vertex_num)))
    (local.set $x (f64.load offset=0 (local.get $vertex_mem_location)))
    (local.set $y (f64.load offset=8 (local.get $vertex_mem_location)))
    (local.set $z (f64.load offset=16 (local.get $vertex_mem_location)))

    ;; denominator used for calculating perspective projection
    (local.set $perspective_denominator
      (f64.sub
          (f64.const 1)
          (f64.div
            (local.get $z)
            (global.get $VIEW_DISTANCE)
          )
      )
    )

    ;; shrink view
    (local.set $x (f64.mul (local.get $x) (global.get $SCALE_X)))
    (local.set $z (f64.mul (local.get $z) (global.get $SCALE_Z)))

    (local.set $y (f64.add (local.get $y) (global.get $TRANSLATE_Y)))

    ;; rotate about x axis
    ;; x' = x
    (local.set $temp2_x (local.get $x))
    ;; y' = y cos θ − z sin θ
    (local.set $temp2_y 
      (f64.sub
        (f64.mul 
          (local.get $y) 
          (call $cos
            (global.get $X_THETA)
          )
        )
        (f64.mul 
          (local.get $z) 
          (call $sin
            (global.get $X_THETA)
          )
        )
      )
    )
    ;; z' = y sin θ + z cos θ
    (local.set $temp2_z 
      (f64.add
        (f64.mul 
          (local.get $y) 
          (call $sin
            (global.get $X_THETA)
          )
        )
        (f64.mul 
          (local.get $z) 
          (call $cos
            (global.get $X_THETA)
          )
        )
      )
    )
    

    (local.set $x (local.get $temp2_x))
    (local.set $y (local.get $temp2_y))
    (local.set $z (local.get $temp2_z))

    ;; add perspective projection
    (local.set $x
      (f64.div
        (local.get $x)
        (local.get $perspective_denominator)
      )
    )
    (local.set $y
      (f64.div
        (local.get $y)
        (local.get $perspective_denominator)
      )
    )
    (local.set $z
      (f64.div
        (local.get $z)
        (local.get $perspective_denominator)
      )
    )

    ;; convert x, y, z from (-1, 1) coordinates to canvas coordinates (0, WIDTH), etc.
    (local.set $x
      (call $map
        (local.get $x)
        (f64.const -1)
        (f64.const 1)
        (f64.const 0)
        (f64.convert_i32_u (global.get $WIDTH))
      )
    )
    (local.set $y
      (call $map
        (local.get $y)
        (f64.const -1)
        (f64.const 1)
        (f64.const 0)
        (f64.convert_i32_u (global.get $HEIGHT))
      )
    )
    (local.set $z
      (call $map
        (local.get $z)
        (f64.const -1)
        (f64.const 1)
        (f64.const 0)
        (f64.convert_i32_u (global.get $DEPTH))
      )
    )

    (i32.trunc_sat_f64_s (local.get $x))
    (i32.trunc_sat_f64_s (local.get $y))
  )

  (func $connect_vertex (param $vertex_num i32)
    (local $next_row_neighbor i32)
    (local $vertex_mem_location i32)
    (local $z_zero_to_one f64)

    (local.set $next_row_neighbor
      (i32.add 
        (local.get $vertex_num)
        (global.get $NUM_VERTICES_SQRT)
      )
    )

    ;; use z index to darken "incoming" vertices
    (local.set $vertex_mem_location (call $vertex_num_to_mem_location (local.get $vertex_num)))
    ;; cube root increases vision distance
    (local.set $z_zero_to_one 
      (call $cbrt
         (f64.load offset=16 (local.get $vertex_mem_location))
      )
    )

    ;; draw next vertex if it's not the last in it's row
    (if
      (i32.ne
        (i32.rem_u
          (i32.add
            (local.get $vertex_num)
            (i32.const 1)
          )
          (global.get $NUM_VERTICES_SQRT)
        )
        (i32.const 0)
      )
      (then
        (call $draw_line
          (call $get_vertex_in_screen_coords (local.get $vertex_num))
          (call $get_vertex_in_screen_coords (i32.add (local.get $vertex_num) (i32.const 1)))
          (i32.trunc_sat_f64_u (f64.mul (f64.const 0x80) (local.get $z_zero_to_one)))
          (i32.trunc_sat_f64_u (f64.mul (f64.const 0x50) (local.get $z_zero_to_one)))
          (i32.const 0x00)
          (i32.const 0xff)
        )
      )
    )

    (if
      (i32.lt_u
        (local.get $next_row_neighbor)
        (global.get $NUM_VERTICES)
      )
      (then
        (call $draw_line
          (call $get_vertex_in_screen_coords (local.get $vertex_num))
          (call $get_vertex_in_screen_coords (local.get $next_row_neighbor))
          (i32.trunc_sat_f64_u (f64.mul (f64.const 0xa0) (local.get $z_zero_to_one)))
          (i32.trunc_sat_f64_u (f64.mul (f64.const 0x30) (local.get $z_zero_to_one)))
          (i32.const 0x00)
          (i32.const 0xff)
        )
      )
    )
  )

  (func $for_each (param $func_ref i32) (param $start_i i32) (param $end_i i32) (param $step i32)
    (local $i i32)
    (local.set $i (local.get $start_i))
    (loop $loop
      (if (i32.lt_s (local.get $i) (local.get $end_i))
        (then
          ;; perform indicated callback
          (call_indirect (type $ForEachCallback) (local.get $i) (local.get $func_ref))
          (local.set $i (i32.add (local.get $i) (local.get $step)))
          br $loop
        )
        (else return)
      )
    )
  )

  ;; EXTERNAL FUNCTIONS
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  (func (export "add_x_theta") (param f64)
    (global.set $X_THETA 
      (call $f64_clamp
        (f64.const -0.75)
        (f64.add (global.get $X_THETA) (local.get 0))
        (f64.const 0.75)
      )
    )
  )

  ;; prepare state
  (func (export "init")
    ;; set num pixels
    global.get $HEIGHT
    global.get $WIDTH
    i32.mul
    global.set $NUM_PIXELS

    ;; set canvas memory length
    global.get $NUM_PIXELS
    global.get $BYTES_PER_PX
    i32.mul
    global.set $CANVAS_MEMORY_LENGTH

    global.get $NUM_VERTICES_SQRT
    global.get $NUM_VERTICES_SQRT
    i32.mul
    global.set $NUM_VERTICES

    ;; num_vertices = (width / distance_between_pixels) * (depth / distance_between_pixels)
    ;; num_vertices = (width * depth) / (distance_between_pixels ** 2)
    ;; (distance_between_pixels ** 2) = (width * depth) / num_vertices
    ;; distance_between_pixels = sqrt((width * depth) / num_vertices)
    (global.set $INITIAL_PX_BETWEEN_VERTICES
      (i32.trunc_sat_f64_u
        (call $sqrt
          (f64.div
            (f64.convert_i32_u
              (i32.mul
                (global.get $WIDTH)
                (global.get $DEPTH)
              )
            )
            (f64.convert_i32_u (global.get $NUM_VERTICES))
          )
        )
      )
    )

    ;; set vertex memory length
    global.get $NUM_VERTICES
    global.get $BYTES_PER_VERTEX
    i32.mul
    global.get $VERTEX_MEMORY_OFFSET
    i32.add
    global.set $VERTEX_MEMORY_LENGTH

    ;; set vertex memory offset
    global.get $CANVAS_MEMORY_OFFSET
    global.get $CANVAS_MEMORY_LENGTH
    i32.add
    global.set $VERTEX_MEMORY_OFFSET

    ;; distribute vertices equally throughout 3d space
    (call $init_vertices)
  )

  ;; update state on every tick
  (func (export "update")
    (global.set $TIME (f64.add (global.get $TIME) (global.get $TIME_INCREMENT)))

    ;; update vertex positions
    (call $for_each
      (global.get $UPDATE_VERTEX)
      (i32.const 0)
      (global.get $NUM_VERTICES)
      (i32.const 1)
    )

    ;; clear canvas
    (call $clear_canvas)

    ;; draw points
    (call $for_each
      (global.get $CONNECT_VERTEX)
      (i32.const 0)
      (global.get $NUM_VERTICES)
      (i32.const 1)
    )
  )
)