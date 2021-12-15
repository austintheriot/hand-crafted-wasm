(module
  ;; IMPORTS
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  (import "Math" "cbrt" (func $cbrt (param f64) (result f64)))
  (import "Math" "sin" (func $sin (param f64) (result f64)))
  (import "Math" "cos" (func $cos (param f64) (result f64)))
  (import "noise" "perlin_noise" (func $perlin_noise (param f64) (param f64) (param f64) (result f64)))
  (import "console" "log" (func $log (param i32)))
  (import "console" "log" (func $log_float (param f64)))

  ;; MEMORY
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  (memory $memory (export "memory") 1000)

  ;; function tables
  (type $ForEachCallback (func (param i32))) 
  (table funcref (elem $update_vertex_offsets $draw_vertex))
  (global $UPDATE_VERTEX i32 (i32.const 0))
  (global $DRAW_VERTEX i32 (i32.const 1))

  ;; canvas data (no memory offset)
  (global $WIDTH (export "WIDTH") i32 (i32.const 300))
  (global $HEIGHT (export "HEIGHT") i32 (i32.const 300))
  (global $DEPTH i32 (i32.const 300))
  (global $VIEW_DISTANCE f64 (f64.const 8))
  (global $DT f64 (f64.const 0.01))
  (global $Y_THETA (mut f64) (f64.const 1))
  (global $X_THETA (mut f64) (f64.const 0.5))
  (global $SCALE (mut f64) (f64.const 0.55))
  (global $TIME (mut f64) (f64.const 0))
  (global $NUM_PIXELS (mut i32) (i32.const 0))
  (global $BYTES_PER_PX i32 (i32.const 4))
  (global $MEM_NOP i32 (i32.const -1))
  (global $CANVAS_MEMORY_OFFSET (export "CANVAS_MEMORY_OFFSET") i32 (i32.const 0)) 
  (global $CANVAS_MEMORY_LENGTH (export "CANVAS_MEMORY_LENGTH") (mut i32) (i32.const 0))

  ;; vertex data (after canvas data)
  (global $INITIAL_PX_BETWEEN_VERTICES (mut i32) (i32.const 0))
  (global $NUM_VERTICES i32 (i32.const 1_000))
  ;; bytes per vertex (x, y, z) => (f64, f64, f64) => (8 bytes, 8 bytes, 8 bytes) => 24 bytes 
  (global $BYTES_PER_VERTEX i32 (i32.const 24))
  (global $VERTEX_MEMORY_OFFSET (mut i32) (i32.const 0))
  (global $VERTEX_MEMORY_LENGTH (mut i32) (i32.const 0))

  (global $VERTEX_DISPLACEMENT_OFFSET (mut i32) (i32.const 0))
  

  ;; INTERNAL FUNCTIONS
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

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

  (func $vertex_displacement_mem_location (param $i i32) (result i32)
    (i32.add 
      (global.get $VERTEX_DISPLACEMENT_OFFSET)
      (i32.mul
        (global.get $BYTES_PER_VERTEX)
        (local.get $i)
      )
    )
  )

 (func $init_vertices
    (local $vertex_mem_location i32)
    (local $x f64)
    (local $y f64)
    (local $z f64)
    (local $width_float f64)
    (local $height_float f64)
    (local $depth_float f64)
    (local $initial_px_between_vertices_float f64)
    (local $vertex_num i32)

    (local.set $width_float (f64.convert_i32_u (global.get $WIDTH)))
    (local.set $height_float (f64.convert_i32_u (global.get $HEIGHT)))
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

          ;; iterate through y
          (local.set $y (f64.const 0))
          (loop $loop_y
            (if (f64.lt (local.get $y) (local.get $height_float))
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
                        (call $map
                          (local.get $y)
                          (f64.const 0)
                          (local.get $height_float)
                          (f64.const -1)
                          (f64.const 1)
                        )
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


                (local.set $y (f64.add (local.get $y) (local.get $initial_px_between_vertices_float)))
                br $loop_y
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
    (local $vertex_displacement_mem_location i32)
    (local $x f64)
    (local $y f64)
    (local $z f64)

    ;; load vertex data
    (local.set $vertex_mem_location (call $vertex_num_to_mem_location (local.get $vertex_num)))
    (local.set $vertex_displacement_mem_location (call $vertex_displacement_mem_location (local.get $vertex_num)))
    (local.set $x 
      (f64.add 
        (f64.load offset=0 (local.get $vertex_mem_location))
        (global.get $TIME)
      )
    )
    (local.set $y 
      (f64.add
        (f64.load offset=8 (local.get $vertex_mem_location)) 
        (global.get $TIME) 
      )
    )
    (local.set $z 
      (f64.add
        (f64.load offset=16 (local.get $vertex_mem_location))
        (global.get $TIME)
      )
    )

    ;; (f64.store offset=0
    ;;   (local.get $vertex_displacement_mem_location)
    ;;   (f64.mul
    ;;     (f64.sub
    ;;       (call $perlin_noise (local.get $x) (local.get $y) (local.get $z))
    ;;       (f64.const 0.5)
    ;;     )
    ;;     (f64.const 1)
    ;;   )
    ;; )
    ;; (f64.store offset=8
    ;;   (local.get $vertex_displacement_mem_location)
    ;;   (f64.mul
    ;;     (f64.sub
    ;;       (call $perlin_noise (local.get $x) (local.get $y) (local.get $z))
    ;;       (f64.const 0.5)
    ;;     )
    ;;     (f64.const 1)
    ;;   )
    ;; )
    ;; (f64.store offset=16
    ;;   (local.get $vertex_displacement_mem_location)
    ;;   (f64.mul
    ;;     (f64.sub
    ;;       (call $perlin_noise (local.get $x) (local.get $y) (local.get $z))
    ;;       (f64.const 0.5)
    ;;     )
    ;;     (f64.const 1)
    ;;   )
    ;; )
  )

  (func $canvas_coords_to_canvas_mem_index (param $x i32) (param $y i32) (param $z i32) (result i32)
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

  ;; set canvas color as opaque white
  (func $clear_canvas
    (memory.fill
      (global.get $CANVAS_MEMORY_OFFSET)
      (i32.const 0) 
      (i32.add (global.get $CANVAS_MEMORY_OFFSET) (global.get $CANVAS_MEMORY_LENGTH))
    )
  )

  (func $draw_pixel (param $x i32) (param $y i32) (param $z i32) 
    (param $r i32) (param $g i32) (param $b i32) (param $a i32)
    (local $canvas_mem_index i32)

    (local.set $canvas_mem_index 
      (call $canvas_coords_to_canvas_mem_index 
        (local.get $x)
        (local.get $y)
        (local.get $z)
      )
    )

    ;; ignore coordinates that fall outside of (-1, 1) range
    (if (i32.eq (local.get $canvas_mem_index) (global.get $MEM_NOP))
      (then return)
    )
    
    ;; add colors from previous pixels together (max out at 0xff for each color band)
    (i32.store8
      offset=0
      (local.get $canvas_mem_index)
      (call $i32_min
        (i32.add 
          (i32.load8_u 
            (local.get $canvas_mem_index)
          ) 
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
          (i32.load8_u 
            (local.get $canvas_mem_index)
          ) 
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
          (i32.load8_u 
            (local.get $canvas_mem_index)
          ) 
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
          (i32.load8_u 
            (local.get $canvas_mem_index)
          ) 
          (local.get $a)
        )
        (i32.const 0xff)
      )
    )
  )

  (func $draw_vertex (param $vertex_num i32)
    (local $vertex_mem_location i32)
    (local $vertex_displacement_mem_location i32)
    (local $x f64)
    (local $y f64)
    (local $z f64)
    (local $temp1_x f64)
    (local $temp1_y f64)
    (local $temp1_z f64)
    (local $temp2_x f64)
    (local $temp2_y f64)
    (local $temp2_z f64)
    (local $perspective_denominator f64)
    (local $x_cos f64)
    (local $z_sin f64)

    (local.set $vertex_mem_location (call $vertex_num_to_mem_location (local.get $vertex_num)))
    (local.set $vertex_displacement_mem_location (call $vertex_displacement_mem_location (local.get $vertex_num)))
    (local.set $x (f64.load offset=0 (local.get $vertex_mem_location)))
    (local.set $y (f64.load offset=8 (local.get $vertex_mem_location)))
    (local.set $z (f64.load offset=16 (local.get $vertex_mem_location)))

    ;; add in noise
    (local.set $x (f64.add (local.get $x) (f64.load offset=0 (local.get $vertex_displacement_mem_location))))
    (local.set $y (f64.add (local.get $y) (f64.load offset=8 (local.get $vertex_displacement_mem_location))))
    (local.set $z (f64.add (local.get $z) (f64.load offset=16 (local.get $vertex_displacement_mem_location))))

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
    (local.set $x (f64.mul (local.get $x) (global.get $SCALE)))
    (local.set $y (f64.mul (local.get $y) (global.get $SCALE)))
    (local.set $z (f64.mul (local.get $z) (global.get $SCALE)))

    ;; rotate about y axis
    ;; x' = x cos θ + z sin θ
    (local.set $temp1_x 
      (f64.add
        (f64.mul 
          (local.get $x) 
          (call $cos
            (global.get $Y_THETA)
          )
        )
        (f64.mul 
          (local.get $z) 
          (call $sin
            (global.get $Y_THETA)
          )
        )
      )
    )
    ;; y' = y
    (local.set $temp1_y (local.get $y))
    ;; z' = −x sin θ + z cos θ
    (local.set $temp1_z
      (f64.add
        (f64.mul
          (f64.mul 
            (local.get $x) 
            (call $sin
              (global.get $Y_THETA)
            )
          )
          (f64.const -1)
        )
        (f64.mul 
          (local.get $z) 
          (call $cos
            (global.get $Y_THETA)
          )
        )
      )
    )

    ;; rotate about x axis
    ;; x' = x
    (local.set $temp2_x (local.get $temp1_x))
    ;; y' = y cos θ − z sin θ
    (local.set $temp2_y 
      (f64.sub
        (f64.mul 
          (local.get $temp1_y) 
          (call $cos
            (global.get $X_THETA)
          )
        )
        (f64.mul 
          (local.get $temp1_z) 
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
          (local.get $temp1_y) 
          (call $sin
            (global.get $X_THETA)
          )
        )
        (f64.mul 
          (local.get $temp1_z) 
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
    ;; (local.set $x
    ;;   (f64.div
    ;;     (local.get $x)
    ;;     (local.get $perspective_denominator)
    ;;   )
    ;; )
    ;; (local.set $y
    ;;   (f64.div
    ;;     (local.get $y)
    ;;     (local.get $perspective_denominator)
    ;;   )
    ;; )
    ;; (local.set $z
    ;;   (f64.div
    ;;     (local.get $z)
    ;;     (local.get $perspective_denominator)
    ;;   )
    ;; )
    
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

    (call $draw_pixel
      ;; truncate float to ingteger (canvas coordinates)
      (i32.trunc_sat_f64_s (local.get $x))
      (i32.trunc_sat_f64_s (local.get $y))
      (i32.trunc_sat_f64_s (local.get $z))

      ;; r g b a
      (i32.const 0x40)
      (i32.const 0x70)
      (i32.const 0xcc)
      (i32.const 0xff)
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

  (func (export "add_y_theta") (param f64)
    (global.set $Y_THETA (f64.add (global.get $Y_THETA) (local.get 0)))
  )
  (func (export "add_x_theta") (param f64)
    (global.set $X_THETA (f64.add (global.get $X_THETA) (local.get 0)))
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

    ;; num_vertices = (width /distance_between_pixels) * (height / distance_between_pixels) * (depth / distance_between_pixels)
    ;; num_vertices = (width * height * depth) / (distance_between_pixels ** 3)
    ;; (distance_between_pixels ** 3) = (width * height * depth) / num_vertices
    ;; distance_between_pixels = cbrt((width * height * depth) / num_vertices)
    (global.set $INITIAL_PX_BETWEEN_VERTICES
      (i32.trunc_sat_f64_u
        (call $cbrt
          (f64.div
            (f64.convert_i32_u
              (i32.mul
                (i32.mul
                  (global.get $WIDTH)
                  (global.get $HEIGHT)
                )
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

    ;; set vertex memory copy offset
    global.get $VERTEX_MEMORY_OFFSET
    global.get $VERTEX_MEMORY_LENGTH
    i32.add
    global.set $VERTEX_DISPLACEMENT_OFFSET

    ;; distribute vertices equally throughout 3d space
    (call $init_vertices)
  )

  ;; update state on every tick
  (func (export "update")
    (global.set $TIME (f64.add (global.get $TIME) (f64.const 0.01)))

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
      (global.get $DRAW_VERTEX)
      (i32.const 0)
      (global.get $NUM_VERTICES)
      (i32.const 1)
    )
  )
)