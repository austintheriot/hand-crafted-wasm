(module
  ;; TODOS
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;; - get rid of unneccessary exporrts (all the camera globals)
  ;; - get rid of unused imports (console logs, etc.)



  ;; IMPORTS
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  (import "Math" "random" (func $random (result f64)))
  (import "Math" "tan" (func $tan (param f64) (result f64)))
  (import "Math" "cos" (func $cos (param f64) (result f64)))
  (import "Math" "sin" (func $sin (param f64) (result f64)))
  (import "Math" "pow" (func $pow (param f64) (param f64) (result f64)))
  (global $PI (import "Math" "PI") f64)
  (import "console" "log" (func $log (param i32)))
  (import "console" "log" (func $log_2 (param i32) (param i32)))
  (import "console" "log" (func $log_float (param f64)))
  (import "console" "log" (func $log_float_2 (param f64) (param f64)))
  (import "error" "throw" (func $throw (param i32)))

  ;; update actual canvas dimensions based on inner aspect-ratio calculations
  (import "canvas" "updateCanvasDimensions" (func $update_canvas_dimensions (param $width i32) (param $height i32)))

  ;; MEMORY
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  (memory $memory (export "memory") 2000)

  ;; CANVAS CONSTANTS
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  ;; width in pixels--this also doubles as the camera_width
  (global $canvas_width (export "canvas_width") (mut i32) (i32.const 0))

  ;; height in pixels--this also doubles as the camera_height
  (global $canvas_height (export "canvas_height") (mut i32) (i32.const 0))

  ;; largest possible size the canvas can be in any one direction in pixels
  (global $max_dimension i32 (i32.const 100))

  ;; 100w * 100h * 4 bytes per pixel = 0-40,000
  ;; @todo -- calculate ending position dynamically to allow manipulating dimensions dynamically

  ;; GENERAL CONSTANTS
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  ;; if result matches this value, then perform nop
  (global $nop_flag i32 (i32.const -1))

  (global $bytes_per_px (export "bytes_per_pixel") i32 (i32.const 4))

  ;; RENDERING CONSTANTS
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;; (global $width f64 (f64.const 0))
  ;; (global $height f64 (f64.const 0))
  ;; (global $now f64 (f64.const 0))
  
  ;; should match width of canvas in pixels
  (global $aperature (export "aperture") (mut f64) (f64.const 0.0))

  (global $focus_distance (export "focus_distance") (mut f64) (f64.const 0.75))

  (global $lens_radius (export "lens_radius") (mut f64) (f64.const 0.0))

  ;; PI / 3.0 -- stored in radians
  (global $camera_field_of_view (export "camera_field_of_view") (mut f64) (f64.const 1.0471975511965976))

  (global $camera_h (export "camera_h") (mut f64) (f64.const 0.0))

  (global $focal_length (export "focal_length") (mut f64) (f64.const 1.0))

  (global $pitch (export "pitch") (mut f64) (f64.const 0.0))

  ;; look down the z-axis by default
  (global $yaw (export "yaw") (mut f64) (f64.const -90.0))

  (global $vup_x (export "vup_x") (mut f64) (f64.const 0.0))
  (global $vup_y (export "vup_y") (mut f64) (f64.const 1.0))
  (global $vup_z (export "vup_z") (mut f64) (f64.const 0.0))

  ;; PI / 3.0 - stored in radians
  (global $camera_origin_x (export "camera_origin_x") (mut f64) (f64.const 0.0))
  (global $camera_origin_y (export "camera_origin_y") (mut f64) (f64.const 0.0))
  (global $camera_origin_z (export "camera_origin_z") (mut f64) (f64.const 1.0))

  (global $aspect_ratio (export "aspect_ratio") (mut f64) (f64.const 0.0))

  (global $camera_front_x (export "camera_front_x") (mut f64) (f64.const 0.0))
  (global $camera_front_y (export "camera_front_y") (mut f64) (f64.const 0.0))
  (global $camera_front_z (export "camera_front_z") (mut f64) (f64.const 0.0))

  (global $u_x (export "u_x") (mut f64) (f64.const 0.0))
  (global $u_y (export "u_y") (mut f64) (f64.const 0.0))
  (global $u_z (export "u_z") (mut f64) (f64.const 0.0))

  (global $v_x (export "v_x") (mut f64) (f64.const 0.0))
  (global $v_y (export "v_y") (mut f64) (f64.const 0.0))
  (global $v_z (export "v_z") (mut f64) (f64.const 0.0))
  
  (global $w_x (export "w_x") (mut f64) (f64.const 0.0))
  (global $w_y (export "w_y") (mut f64) (f64.const 0.0))
  (global $w_z (export "w_z") (mut f64) (f64.const 0.0))

  (global $sync_viewport_height (export "sync_viewport_height") (mut f64) (f64.const 0.0))
  (global $sync_viewport_width (export "sync_viewport_width") (mut f64) (f64.const 0.0))

  (global $horizontal_x (export "horizontal_x") (mut f64) (f64.const 0.0))
  (global $horizontal_y (export "horizontal_y") (mut f64) (f64.const 0.0))
  (global $horizontal_z (export "horizontal_z") (mut f64) (f64.const 0.0))

  (global $vertical_x (export "vertical_x") (mut f64) (f64.const 0.0))
  (global $vertical_y (export "vertical_y") (mut f64) (f64.const 0.0))
  (global $vertical_z (export "vertical_z") (mut f64) (f64.const 0.0))

  (global $lower_left_corner_x (export "lower_left_corner_x") (mut f64) (f64.const 0.0))
  (global $lower_left_corner_y (export "lower_left_corner_y") (mut f64) (f64.const 0.0))
  (global $lower_left_corner_z (export "lower_left_corner_z") (mut f64) (f64.const 0.0))

  (global $look_at_x (export "look_at_x") (mut f64) (f64.const 1))
  (global $look_at_y (export "look_at_y") (mut f64) (f64.const 1))
  (global $look_at_z (export "look_at_z") (mut f64) (f64.const 1))

  ;; INTERNAL FUNCTIONS
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  (func $degrees_to_radians (param $degrees f64) (result f64)
    (f64.div
      (f64.mul
        (local.get $degrees)
        (global.get $PI)
      )
      (f64.const 180.0)
    )
  )

  (func $vec_len_squared (param $x f64) (param $y f64) (param $z f64) (result f64)
    (f64.add
      (f64.add
        (call $pow 
          (local.get $x)
          (f64.const 2.0)
        )
        (call $pow 
          (local.get $y)
          (f64.const 2.0)
        )
      )
      (call $pow 
        (local.get $z)
        (f64.const 2.0)
      )
    )
  )

  (func $vec_len (param $x f64) (param $y f64) (param $z f64) (result f64)
    (f64.sqrt
      (call $vec_len_squared (local.get $x) (local.get $y) (local.get $z))
    )
  )

  ;; $component refers to which item in the vec to get the value back from
  ;; (since binaryen currently is failing to allow multivalue return)
  (func $vec_normalize 
    (param $x f64) 
    (param $y f64)
    (param $z f64) 
    (result f64 f64 f64)
    (local $length f64)

    (local.set $length
      (call $vec_len (local.get $x) (local.get $y) (local.get $z))
    )

    (f64.div (local.get $x) (local.get $length))
    (f64.div (local.get $y) (local.get $length))
    (f64.div (local.get $z) (local.get $length)) 
  )

  ;; normalize one component when length is already known
  (func $vec_normalize_with_length (param $xyz f64) (param $length f64)
    (f64.div (local.get $xyz) (local.get $length))
  )

  ;; $component refers to which item in the vec to get the value back from
  ;; (since binaryen currently is failing to allow multivalue return)
  (func $vec_cross 
    (param $x1 f64) 
    (param $y1 f64)
    (param $z1 f64)
    (param $x2 f64) 
    (param $y2 f64)
    (param $z2 f64)
    (result f64 f64 f64)
    
   (f64.sub
      (f64.mul
        (local.get $y1)
        (local.get $z2)
      ) 
      (f64.mul
        (local.get $z1)
        (local.get $y2)
      )
    )
    (f64.sub
      (f64.mul
        (local.get $z1)
        (local.get $x2)
      ) 
      (f64.mul
        (local.get $x1)
        (local.get $z2)
      )
    )
    (f64.sub
      (f64.mul
        (local.get $x1)
        (local.get $y2)
      ) 
      (f64.mul
        (local.get $y1)
        (local.get $x2)
      )
    )
  )

  ;; runs through entire camera pipeline to update all values
  (func $update_camera_values
    (local $u_cross_result_x f64)
    (local $u_cross_result_y f64)
    (local $u_cross_result_z f64)

    (local $v_cross_result_x f64)
    (local $v_cross_result_y f64)
    (local $v_cross_result_z f64)

    (local $w_result_x f64)
    (local $w_result_y f64)
    (local $w_result_z f64)

    (local $U_result_x f64)
    (local $U_result_y f64)
    (local $U_result_z f64)

    (local $example f64)


    ;; update aspect_ratio
    (global.set $aspect_ratio
      (f64.div 
        (f64.convert_i32_u
          (global.get $canvas_width)
        )
        (f64.convert_i32_u
          (global.get $canvas_height)
        )
      )
    )
    
    ;; update camera_h
    (global.set $camera_h
      (call $tan 
        (f64.div
          (global.get $camera_field_of_view)
          (f64.const 2.0)
        )
      )
    )

    ;; update camera_front
    (global.set $camera_front_x
      (f64.mul
        (call $cos
          (call $degrees_to_radians
            (global.get $yaw)
          )
        )
        (call $cos
            (call $degrees_to_radians
            (global.get $pitch)
          )
        )
      )
    )
    (global.set $camera_front_y
      (call $sin
        (call $degrees_to_radians
          (global.get $pitch)
        )
      )
    )
    (global.set $camera_front_z
      (f64.mul
        (call $sin
          (call $degrees_to_radians
            (global.get $yaw)
          )
        )
        (call $cos
            (call $degrees_to_radians
            (global.get $pitch)
          )
        )
      )
    )

    ;; update look_at
    (global.set $look_at_x
      (f64.add
        (global.get $camera_origin_x)
        (global.get $camera_front_x)
      )
    )
    (global.set $look_at_y
      (f64.add
        (global.get $camera_origin_y)
        (global.get $camera_front_y)
      )
    )
    (global.set $look_at_z
      (f64.add
        (global.get $camera_origin_z)
        (global.get $camera_front_z)
      )
    )

    ;; prepare data before calculating w
    ;; camera_origin - look_at
    (local.set $w_result_x
      (f64.sub
        (global.get $camera_origin_x)
        (global.get $look_at_x)
      )
    )
    (local.set $w_result_y
      (f64.sub
        (global.get $camera_origin_y)
        (global.get $look_at_y)
      )
    )
    (local.set $w_result_z
      (f64.sub
        (global.get $camera_origin_z)
        (global.get $look_at_z)
      )
    )

    ;; update w
    (global.set $w_x
      (call $vec_normalize
        (local.get $w_result_x)
        (local.get $w_result_y)
        (local.get $w_result_z)
      )
      (drop)
      (drop)
    )
    (global.set $w_y
      (call $vec_normalize
        (local.get $w_result_x)
        (local.get $w_result_y)
        (local.get $w_result_z)
      )
      (drop)
    )
    (global.set $w_z
      (call $vec_normalize
        (local.get $w_result_x)
        (local.get $w_result_y)
        (local.get $w_result_z)
      )
    )

    ;; prepare cross product for calculating u
    (local.set $u_cross_result_x
      (call $vec_cross
        (global.get $vup_x)
        (global.get $vup_y)
        (global.get $vup_z)
        (global.get $w_x)
        (global.get $w_y)
        (global.get $w_z)
      )
      (drop)
      (drop)
    )
    (local.set $u_cross_result_y
      (call $vec_cross
        (global.get $vup_x)
        (global.get $vup_y)
        (global.get $vup_z)
        (global.get $w_x)
        (global.get $w_y)
        (global.get $w_z)
      )
      (drop)
    )
    (local.set $u_cross_result_z
      (call $vec_cross
        (global.get $vup_x)
        (global.get $vup_y)
        (global.get $vup_z)
        (global.get $w_x)
        (global.get $w_y)
        (global.get $w_z)
      )
    )

    ;; update u
    (global.set $u_x
      (call $vec_normalize
        (local.get $u_cross_result_x)
        (local.get $u_cross_result_y)
        (local.get $u_cross_result_z)
      )
      (drop)
      (drop)
    )
    (global.set $u_y
      (call $vec_normalize
        (local.get $u_cross_result_x)
        (local.get $u_cross_result_y)
        (local.get $u_cross_result_z)
      )
      (drop)
    )
    (global.set $u_z
      (call $vec_normalize
        (local.get $u_cross_result_x)
        (local.get $u_cross_result_y)
        (local.get $u_cross_result_z)
      )
    )

    ;; prepare cross product for calculating v
    (local.set $v_cross_result_x
      (call $vec_cross
        (global.get $w_x)
        (global.get $w_y)
        (global.get $w_z)
        (global.get $u_x)
        (global.get $u_y)
        (global.get $u_z)
      )
      (drop)
      (drop)
    )
    (local.set $v_cross_result_y
      (call $vec_cross
        (global.get $w_x)
        (global.get $w_y)
        (global.get $w_z)
        (global.get $u_x)
        (global.get $u_y)
        (global.get $u_z)
      )
      (drop)
    )
    (local.set $v_cross_result_z
      (call $vec_cross
        (global.get $w_x)
        (global.get $w_y)
        (global.get $w_z)
        (global.get $u_x)
        (global.get $u_y)
        (global.get $u_z)
      )
    )

    ;; update v
    (global.set $v_x
      (call $vec_normalize
        (local.get $v_cross_result_x)
        (local.get $v_cross_result_y)
        (local.get $v_cross_result_z)
      )
      (drop)
      (drop)
    )
    (global.set $v_y
      (call $vec_normalize
        (local.get $v_cross_result_x)
        (local.get $v_cross_result_y)
        (local.get $v_cross_result_z)
      )
      (drop)
    )
    (global.set $v_z
      (call $vec_normalize
        (local.get $v_cross_result_x)
        (local.get $v_cross_result_y)
        (local.get $v_cross_result_z)
      )
    )

    ;; update sync_viewport_height
    (global.set $sync_viewport_height
      (f64.mul 
        (f64.const 2.0)
        (global.get $camera_h)
      )
    )

    ;; update sync_viewport_width
    (global.set $sync_viewport_width
      (f64.mul
        (global.get $sync_viewport_height)
        (global.get $aspect_ratio)
      )
    )

    ;; update horizontal
    (global.set $horizontal_x
      (f64.mul
        (f64.mul
          (global.get $u_x)
          (global.get $sync_viewport_width)
        )
        (global.get $focus_distance)
      )
    )
    (global.set $horizontal_y
      (f64.mul
        (f64.mul
          (global.get $u_y)
          (global.get $sync_viewport_width)
        )
        (global.get $focus_distance)
      )
    )
    (global.set $horizontal_z
      (f64.mul
        (f64.mul
          (global.get $u_z)
          (global.get $sync_viewport_width)
        )
        (global.get $focus_distance)
      )
    )

    ;; update vertical
    (global.set $vertical_x
      (f64.mul
        (f64.mul
          (global.get $v_x)
          (global.get $sync_viewport_height)
        )
        (global.get $focus_distance)
      )
    )
    (global.set $vertical_y
      (f64.mul
        (f64.mul
          (global.get $v_y)
          (global.get $sync_viewport_height)
        )
        (global.get $focus_distance)
      )
    )
    (global.set $vertical_z
      (f64.mul
        (f64.mul
          (global.get $v_z)
          (global.get $sync_viewport_height)
        )
        (global.get $focus_distance)
      )
    )

    ;; update lower_left_corner
    (global.set $lower_left_corner_x
      (f64.sub
        (f64.sub
          (f64.sub
            (global.get $camera_origin_x)
            (f64.div
              (global.get $horizontal_x)
              (f64.const 2.0)  
            )
          )
          (f64.div
            (global.get $vertical_x)
            (f64.const 2.0)  
          )
        )
        (f64.mul
          (global.get $focus_distance)
          (global.get $w_x)
        )
      )
    )
    (global.set $lower_left_corner_y
      (f64.sub
        (f64.sub
          (f64.sub
            (global.get $camera_origin_y)
            (f64.div
              (global.get $horizontal_y)
              (f64.const 2.0)  
            )
          )
          (f64.div
            (global.get $vertical_y)
            (f64.const 2.0)  
          )
        )
        (f64.mul
          (global.get $focus_distance)
          (global.get $w_y)
        )
      )
    )
    (global.set $lower_left_corner_z
      (f64.sub
        (f64.sub
          (f64.sub
            (global.get $camera_origin_z)
            (f64.div
              (global.get $horizontal_z)
              (f64.const 2.0)  
            )
          )
          (f64.div
            (global.get $vertical_z)
            (f64.const 2.0)  
          )
        )
        (f64.mul
          (global.get $focus_distance)
          (global.get $w_z)
        )
      )
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

  ;; coords should range from 0 to < canvas_length for x
  ;; and 0 to < canvas_height for y
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
            (i32.sub (global.get $canvas_width) (i32.const 1))
          )
        )
        (i32.or
          (i32.lt_s
            (local.get $y)
            (i32.const 0)
          )
          (i32.gt_s
            (local.get $y)
            (i32.sub (global.get $canvas_height) (i32.const 1))
          )
        )
      )
      ;; nooop
      (then 
        (call $throw (i32.const 0))
        (return (global.get $nop_flag))
      )
    )

    ;; actually calculate memory index if not out of bounds
    global.get $canvas_width
    local.get $y
    i32.mul
    local.get $x
    i32.add
    global.get $bytes_per_px
    i32.mul
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

    (local.set $canvas_mem_value
      (i32.load8_u 
        (local.get $canvas_mem_index)
      ) 
    )

    ;; ignore coordinates that fall outside of (-1, 1) range
    (if (i32.eq (local.get $canvas_mem_index) (global.get $nop_flag))
      (then return)
    )
    
    ;; add colors from previous pixels together (max out at 0xff for each color band)
    (i32.store8
      offset=0
      (local.get $canvas_mem_index)
      (call $i32_min
        (local.get $r)
        (i32.const 0xff)
      )
    )
    (i32.store8
      offset=1
      (local.get $canvas_mem_index)
      (call $i32_min
        (local.get $g)
        (i32.const 0xff)
      )
    )
    (i32.store8
      offset=2
      (local.get $canvas_mem_index)
      (call $i32_min
        (local.get $b)
        (i32.const 0xff)
      )
    )
    (i32.store8
      offset=3
      (local.get $canvas_mem_index)
      (call $i32_min
        (local.get $a)
        (i32.const 0xff)
      )
    )
  )

  (func $get_ray_from_camera (result f64 f64 f64)
    ;; todo 
    (f64.const 1) (f64.const 1) (f64.const 1)
  )
  
  ;; s & t should map from 0.0 -> 1.0
  (func $get_pixel_color (param $s f64) (param $t f64)
    ;; (call $draw_pixel 
    ;;   (local.get $i) 
    ;;   (local.get $j)
    ;;   (local.get $rgb_color_x) 
    ;;   (local.get $rgb_color_y)
    ;;   (local.get $rgb_color_x)
    ;;   (i32.const 255)
    ;; )
  )

  (func $iterate_pixels 
    (local $start_i i32) 
    (local $end_i i32) 

    (local $start_j i32) 
    (local $end_j i32) 

    (local $step i32)

    (local $i i32)
    (local $j i32)

    (local $progress_x f64)
    (local $progress_y f64)

    (local $rgb_color_x i32)
    (local $rgb_color_y i32)

    (local $s f64)
    (local $t f64)

    (local.set $step (i32.const 1))
    (local.set $end_i (global.get $canvas_width))
    (local.set $end_j (global.get $canvas_height))

    ;; outer loop - x coords
    (local.set $i (local.get $start_i))
    (loop $outer_loop
      (if (i32.lt_s (local.get $i) (local.get $end_i))
        (then


          (block $inner_block 
            ;; inner loop - y coords
            (local.set $j (local.get $start_j))
            (loop $inner_loop
              (if (i32.lt_s (local.get $j) (local.get $end_j))
                (then

                  ;; convert pixel numbers to coordinates 0->1
                  (local.set $s
                    (f64.div
                      (f64.convert_i32_u (local.get $i))
                      (f64.convert_i32_u (global.get $canvas_width))
                    )
                  )
                   (local.set $t
                    (f64.div
                      (f64.convert_i32_u (local.get $j))
                      (f64.convert_i32_u (global.get $canvas_height))
                    )
                  )

                  (call $get_pixel_color
                    (local.get $s)
                    (local.get $t)
                  )
                  
                  (local.set $j (i32.add (local.get $j) (local.get $step)))
                  ;; return to beginning of loop
                  br $inner_loop
                )
                ;; exit loop
                (else br $inner_block)
              )
            )
          )

          
          (local.set $i (i32.add (local.get $i) (local.get $step)))
          br $outer_loop
        )
        (else return)
      )
    )
  )

  ;; EXPORTS
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  
  ;; save the windows actual size in pixels in wasm memory
  (func $sync_viewport (export "sync_viewport") 
    (param $prev_window_width i32) 
    (param $prev_window_height i32)

    (local $multiplier f64)
    (local $new_canvas_width i32)
    (local $new_canvas_height i32)

    ;; constrain window size to a certain number of pixels in any one direction
    (if (i32.gt_u (local.get $prev_window_width) (local.get $prev_window_height))
      (then 
        ;; width is greater than height
        (local.set $multiplier
          (f64.div 
            (f64.convert_i32_u (global.get $max_dimension))
            (f64.convert_i32_u (local.get $prev_window_width))
          )
        )
      )
      (else 
        ;; height is greater than width
        (local.set $multiplier
          (f64.div 
            (f64.convert_i32_u (global.get $max_dimension))
            (f64.convert_i32_u (local.get $prev_window_height))
          )
        )
      )
    )

    (local.set $new_canvas_width
      (i32.trunc_sat_f64_u
        (f64.mul
          (f64.convert_i32_u (local.get $prev_window_width))
          (local.get $multiplier)
        )
      )
    )

    (local.set $new_canvas_height
      (i32.trunc_sat_f64_u
        (f64.mul
          (f64.convert_i32_u (local.get $prev_window_height))
          (local.get $multiplier)
        )
      )
    )

    (global.set $canvas_width (local.get $new_canvas_width))
    (global.set $canvas_height (local.get $new_canvas_height))
    
    (call $update_canvas_dimensions 
      (local.get $new_canvas_width) 
      (local.get $new_canvas_height)
    )
  )

  ;; called on each tick to update all internal state
  (func (export "update")
    (local $num_pixels i32)

    (call $iterate_pixels (i32.const 0) (i32.const 10000) (i32.const 1))
  )
  
  (func $init 
    (export "init") 
    (param $initial_canvas_width i32) 
    (param $initial_canvas_height i32)

    ;; synchronize window && canvas size with internal state
    (call $sync_viewport 
      (local.get $initial_canvas_width) 
      (local.get $initial_canvas_height)
    )
    (call $update_camera_values)
  )
)