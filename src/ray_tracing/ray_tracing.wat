(module
  ;; TODOS
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;; - get rid of unneccessary exporrts (all the camera globals)
  ;; - get rid of unused imports (console logs, etc.)
  ;; - remove bounds checks from draw_pixel ?
  ;; - calculate memory needed for canvas dynamically to allow manipulating dimensions dynamically

  ;; TYPES
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;  Ray
  ;;  ($origin_vector_x f64)
  ;;  ($origin_vector_y f64)
  ;;  ($origin_vector_z f64)
  ;;  ($direction_vector_x f64)
  ;;  ($direction_vector_y f64)
  ;;  ($direction_vector_z f64)
  ;;
  ;;  HitRecord
  ;;  ($hit_point_x f64)
  ;;  ($hit_point_y f64)
  ;;  ($hit_point_z f64)
  ;;  ($hit_t f64)
  ;;  ($normal_x f64)
  ;;  ($normal_y f64)
  ;;  ($normal_z f64)
  ;;  ($front_face i32)
  ;;  ($material_type i32)
  ;;  ($material_albedo_r f64)
  ;;  ($material_albedo_g f64)
  ;;  ($material_albedo_b f64)
  ;;  ($material_fuzz f64)
  ;;  ($material_refraction_index f64)
  ;; 
  ;;  Sphere - 76 bytes
  ;;  ($center_x f64)
  ;;  ($center_y f64)
  ;;  ($center_z f64)
  ;;  ($radius f64)
  ;;  ($material_type i32)
  ;;  ($material_albedo_r f64)
  ;;  ($material_albedo_g f64)
  ;;  ($material_albedo_b f64)
  ;;  ($material_fuzz f64)
  ;;  ($material_refraction_index f64)

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
  (import "console" "log" (func $log_4 (param i32) (param i32) (param i32) (param i32)))
  (import "console" "log" (func $log_float (param f64)))
  (import "console" "log" (func $log_float_2 (param f64) (param f64)))
  (import "console" "log" (func $log_float_6 (param f64) (param f64) (param f64) (param f64) (param f64) (param f64)))
  (import "error" "throw" (func $throw (param i32)))

  ;; update actual canvas dimensions based on inner aspect-ratio calculations
  (import "canvas" "updateCanvasDimensions" (func $update_canvas_dimensions (param $width i32) (param $height i32)))

  ;; MEMORY
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  (memory $memory (export "memory") 2000)
  ;; Addresses:
  ;; 0-39,999 for canvas pixel data
  ;; 40,000-? for object data

  ;; CANVAS CONSTANTS
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  ;; width in pixels--this also doubles as the camera_width
  (global $canvas_width (export "canvas_width") (mut i32) (i32.const 0))

  ;; height in pixels--this also doubles as the camera_height
  (global $canvas_height (export "canvas_height") (mut i32) (i32.const 0))

  ;; largest possible size the canvas can be in any one direction in pixels
  (global $max_dimension i32 (i32.const 100))

  (global $object_list_ptr i32 (i32.const 40000))
  (global $object_size i32 (i32.const 76))
  (global $object_list_len (mut i32) (i32.const 0))

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

  (global $min_t f64 (f64.const 0.001))
  (global $max_t f64 (f64.const 100000))

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
  (func $vec_normalize_with_length (param $xyz f64) (param $length f64) (result f64)
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

  (func $vec_dot
    (param $x1 f64) 
    (param $y1 f64)
    (param $z1 f64)
    (param $x2 f64) 
    (param $y2 f64)
    (param $z2 f64)
    (result f64)
    
    (f64.add
      (f64.add
        (f64.mul
          (local.get $x1)
          (local.get $x2)
        ) 
        (f64.mul
          (local.get $y1)
          (local.get $y2)
        )
      )
      (f64.mul
        (local.get $z1)
        (local.get $z2)
      ) 
    )
  )

  

  ;; subtract a vec from a vec
  (func $vec_sub_vec
    ;; vec 1
    (param $x1 f64) (param $y1 f64) (param $z1 f64) 
    ;; vec 2
    (param $x2 f64) (param $y2 f64) (param $z2 f64)  
    ;; resulting vec
    (result f64 f64 f64)
    (f64.sub
      (local.get $x1)
      (local.get $x2)
    )
    (f64.sub
      (local.get $y1)
      (local.get $y2)
    )
    (f64.sub
      (local.get $z1)
      (local.get $z2)
    )
  )

  ;; add a vec to a vec
  (func $vec_add_vec
    ;; vec 1
    (param $x1 f64) (param $y1 f64) (param $z1 f64) 
    ;; vec 2
    (param $x2 f64) (param $y2 f64) (param $z2 f64)  
    ;; resulting vec
    (result f64 f64 f64)
    (f64.add
      (local.get $x1)
      (local.get $x2)
    )
    (f64.add
      (local.get $y1)
      (local.get $y2)
    )
    (f64.add
      (local.get $z1)
      (local.get $z2)
    )
  )

  ;; multiply the elements of a vec by the elements in another vec
  (func $vec_mul_vec
    ;; vec 1
    (param $x1 f64) (param $y1 f64) (param $z1 f64) 
    ;; vec 2
    (param $x2 f64) (param $y2 f64) (param $z2 f64)  
    ;; resulting vec
    (result f64 f64 f64)
    (f64.mul
      (local.get $x1)
      (local.get $x2)
    )
    (f64.mul
      (local.get $y1)
      (local.get $y2)
    )
    (f64.mul
      (local.get $z1)
      (local.get $z2)
    )
  )

  ;; adds a constant to a vector
  (func $vec_add_constant (param $x f64) (param $y f64) (param $z f64) (param $constant f64) (result f64 f64 f64)
    (f64.add
      (local.get $x)
      (local.get $constant)
    )
    (f64.add
      (local.get $y)
      (local.get $constant)
    )
    (f64.add
      (local.get $z)
      (local.get $constant)
    )
  )

  ;; divides a vector by a constant
  (func $vec_div_constant (param $x f64) (param $y f64) (param $z f64) (param $constant f64) (result f64 f64 f64)
    (f64.sub
      (local.get $x)
      (local.get $constant)
    )
    (f64.sub
      (local.get $y)
      (local.get $constant)
    )
    (f64.sub
      (local.get $z)
      (local.get $constant)
    )
  )

  ;; multiplies a vector times a constant
  (func $vec_mul_constant (param $x f64) (param $y f64) (param $z f64) (param $constant f64) (result f64 f64 f64)
    (f64.mul
      (local.get $x)
      (local.get $constant)
    )
    (f64.mul
      (local.get $y)
      (local.get $constant)
    )
    (f64.mul
      (local.get $z)
      (local.get $constant)
    )
  )

  ;; subtracts a constant from a vector
  (func $vec_sub_constant (param $x f64) (param $y f64) (param $z f64) (param $constant f64) (result f64 f64 f64)
    (f64.sub
      (local.get $x)
      (local.get $constant)
    )
    (f64.sub
      (local.get $y)
      (local.get $constant)
    )
    (f64.sub
      (local.get $z)
      (local.get $constant)
    )
  )

  ;; linearly interpolates between 2 3d vectors
  (func $vec_interpolate
    (param $x1 f64)
    (param $y1 f64)
    (param $z1 f64)
    (param $x2 f64)
    (param $y2 f64)
    (param $z2 f64)
    (param $percent f64)
    (result f64 f64 f64)

    (local $vector_x f64)
    (local $vector_y f64)
    (local $vector_z f64)

    (local $result_x f64)
    (local $result_y f64)
    (local $result_z f64)

    (local.set $vector_x
      (f64.sub (local.get $x2) (local.get $x1))
    )
    (local.set $vector_y
      (f64.sub (local.get $y2) (local.get $y1))
    )
    (local.set $vector_z
      (f64.sub (local.get $z2) (local.get $z1))
    )

    (f64.add 
      (local.get $x1)
      (f64.mul
        (local.get $vector_x)
        (local.get $percent)
      )
    )
    (f64.add 
      (local.get $y1)
      (f64.mul
        (local.get $vector_y)
        (local.get $percent)
      )
    )
    (f64.add 
      (local.get $z1)
      (f64.mul
        (local.get $vector_z)
        (local.get $percent)
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
    (i32.mul
      (i32.add
        (local.get $x)
        (i32.mul
          (global.get $canvas_width)
          (local.get $y)
        )
      )
      (global.get $bytes_per_px)
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

  ;; Returns a Ray -> origin (x, y, z), direction (x, y, z)
  (func $get_ray_from_camera (param $s f64) (param $t f64) (result f64 f64 f64 f64 f64 f64)
    (local $ray_direction_x f64)
    (local $ray_direction_y f64)
    (local $ray_direction_z f64)

    (local.set $ray_direction_x
      (local.set $ray_direction_y
        (local.set $ray_direction_z
          (call $vec_sub_vec
            (call $vec_add_vec
              (call $vec_add_vec
                (global.get $lower_left_corner_x)
                (global.get $lower_left_corner_y)
                (global.get $lower_left_corner_z)
                (call $vec_mul_constant
                  (global.get $horizontal_x)
                  (global.get $horizontal_y)
                  (global.get $horizontal_z)
                  (local.get $s)
                )
              )
              (call $vec_mul_constant
                (global.get $vertical_x)
                (global.get $vertical_y)
                (global.get $vertical_z)
                (local.get $t)
              )
            )
            (global.get $camera_origin_x)
            (global.get $camera_origin_y)
            (global.get $camera_origin_z)
          )
        )
      )
    )

    ;; camera origin 
    ;; todo - replace this with a randomized amunt in lens circle
    (global.get $camera_origin_x)
    (global.get $camera_origin_y)
    (global.get $camera_origin_z)
    (local.get $ray_direction_x)
    (local.get $ray_direction_y)
    (local.get $ray_direction_z)
  )

  (func $background 
    (param $ray_origin_x f64)
    (param $ray_origin_y f64)
    (param $ray_origin_z f64)
    (param $ray_direction_x f64)
    (param $ray_direction_y f64)
    (param $ray_direction_z f64)
    (result f64 f64 f64)

    (local $unit_direction_x f64)
    (local $unit_direction_y f64)
    (local $unit_direction_z f64)

    (local $t f64)

    (local $gradient_x f64)
    (local $gradient_y f64)
    (local $gradient_z f64)

    (local.set $unit_direction_x
      (local.set $unit_direction_y
        (local.set $unit_direction_z
          (call $vec_normalize
            (local.get $ray_direction_x)
            (local.get $ray_direction_y)
            (local.get $ray_direction_z)
          )
        )
      )
    )

    (local.set $t
      (f64.mul
        (f64.const 0.5)
        (f64.add
          (local.get $unit_direction_y)
          (f64.const 1.0)
        )
      ) 
    )

    (call $vec_interpolate
      (f64.const 1.0)
      (f64.const 1.0)
      (f64.const 1.0)

      (f64.const 0.5)
      (f64.const 0.7)
      (f64.const 1.0)

      (local.get $t)
    )
  )

  (func $ray_at
    ;; Ray data
    (param $ray_origin_x f64)
    (param $ray_origin_y f64)
    (param $ray_origin_z f64)
    (param $ray_direction_x f64)
    (param $ray_direction_y f64)
    (param $ray_direction_z f64)
    (param $hit_t f64)
    (result f64 f64 f64)
    
    (call $vec_mul_constant
      (call $vec_add_vec
        (local.get $ray_origin_x)
        (local.get $ray_origin_y)
        (local.get $ray_origin_z)
        (local.get $ray_direction_x)
        (local.get $ray_direction_y)
        (local.get $ray_direction_z)
      )
      (local.get $hit_t)
    )
  )

  (func $hit_sphere
    ;; Sphere data
    (param $sphere_center_x f64)
    (param $sphere_center_y f64)
    (param $sphere_center_z f64)
    (param $sphere_radius f64)
    (param $sphere_material_type i32)
    (param $sphere_material_albedo_r f64)
    (param $sphere_material_albedo_g f64)
    (param $sphere_material_albedo_b f64)
    (param $sphere_material_fuzz f64)
    (param $sphere_material_refraction_index f64)
    
    ;; used to check which collission was closer when
    ;; there are multiple objects in a scene
    (param $min_t_local f64)
    
    ;; Ray data
    (param $ray_origin_x f64)
    (param $ray_origin_y f64)
    (param $ray_origin_z f64)
    (param $ray_direction_x f64)
    (param $ray_direction_y f64)
    (param $ray_direction_z f64)

    ;; HitRecord data (in)
    (param $in_hit_point_x f64)
    (param $in_hit_point_y f64)
    (param $in_hit_point_z f64)
    (param $in_hit_t f64)
    (param $in_normal_x f64)
    (param $in_normal_y f64)
    (param $in_normal_z f64)
    (param $in_front_face i32)
    (param $in_material_type i32)
    (param $in_material_albedo_r f64)
    (param $in_material_albedo_g f64)
    (param $in_material_albedo_b f64)
    (param $in_material_fuzz f64)
    (param $in_material_refraction_index f64)

    ;; return HitRecord
    (result f64 f64 f64 f64 f64 f64 f64 i32 i32 f64 f64 f64 f64 f64 i32)

    ;; HitRecord data (out)
    (local $out_hit_point_x f64)
    (local $out_hit_point_y f64)
    (local $out_hit_point_z f64)
    (local $out_hit_t f64)
    (local $out_normal_x f64)
    (local $out_normal_y f64)
    (local $out_normal_z f64)
    (local $out_front_face i32)
    (local $out_material_type i32)
    (local $out_material_albedo_r f64)
    (local $out_material_albedo_g f64)
    (local $out_material_albedo_b f64)
    (local $out_material_fuzz f64)
    (local $out_material_refraction_index f64)

    ;; determine whether sphere was hit
    (local $hit_object i32)
    
    ;; sphere collission detection variables
    (local $oc_x f64)
    (local $oc_y f64)
    (local $oc_z f64)
    (local $a f64)
    (local $half_b f64)
    (local $c f64)
    (local $disctriminant f64)
    (local $sqrtd f64)
    (local $root f64)
    (local $outward_normal_x f64)
    (local $outward_normal_y f64)
    (local $outward_normal_z f64)

    ;; initialize HitRecord data (out) with data coming in
    (local.set $out_hit_point_x (local.get $in_hit_point_x ))
    (local.set $out_hit_point_y (local.get $in_hit_point_y ))
    (local.set $out_hit_point_z (local.get $in_hit_point_z ))
    (local.set $out_hit_t (local.get $in_hit_t ))
    (local.set $out_normal_x (local.get $in_normal_x ))
    (local.set $out_normal_y (local.get $in_normal_y ))
    (local.set $out_normal_z (local.get $in_normal_z ))
    (local.set $out_front_face (local.get $in_front_face ))
    (local.set $out_material_type (local.get $in_material_type))
    (local.set $out_material_albedo_r (local.get $in_material_albedo_r))
    (local.set $out_material_albedo_g (local.get $in_material_albedo_g))
    (local.set $out_material_albedo_b (local.get $in_material_albedo_b))
    (local.set $out_material_fuzz (local.get $in_material_fuzz))
    (local.set $out_material_refraction_index (local.get $in_material_refraction_index))

    ;; collission detection with spehere
    (local.set $oc_x
      (local.set $oc_y
        (local.set $oc_z
          (call $vec_sub_vec
            (local.get $ray_origin_x)
            (local.get $ray_origin_y)
            (local.get $ray_origin_z)
            (local.get $sphere_center_x)
            (local.get $sphere_center_y)
            (local.get $sphere_center_z)
          )
        )
      )
    )

    (local.set $a
      (call $vec_len_squared
        (local.get $ray_direction_x)
        (local.get $ray_direction_y)
        (local.get $ray_direction_z)
      )
    )

    (local.set $half_b
      (call $vec_dot
        (local.get $oc_x)
        (local.get $oc_y)
        (local.get $oc_z)
        (local.get $ray_direction_x)
        (local.get $ray_direction_y)
        (local.get $ray_direction_z)
      )
    )

    (local.set $c
      (f64.sub
        (call $vec_len_squared
          (local.get $oc_x)
          (local.get $oc_y)
          (local.get $oc_z)
        )
        (call $pow
          (local.get $sphere_radius)
          (f64.const 2.0)
        )
      )
    )

    (local.set $disctriminant
      (f64.sub
        (call $pow
          (local.get $half_b)
          (f64.const 2.0)
        )
        (f64.mul
          (local.get $a)
          (local.get $c)
        )
      )
    )

    ;; assume a hit and disprove in the following blocks
    (local.set $hit_object (i32.const 1))

    (block $determine_hit
      (if (f64.lt (local.get $disctriminant) (f64.const 0.0))
        (then
          ;; no hit
          (local.set $hit_object (i32.const 0))
          (br $determine_hit)
        )
        (else 
          ;; there was a hit--determine whether it was within an acceptable range
          (local.set $sqrtd
            (f64.sqrt
              (local.get $disctriminant)
            )
          )
          (local.set $root
            (f64.div
              (f64.sub
                (f64.neg 
                  (local.get $half_b)
                )
                (local.get $sqrtd)
              )
              (local.get $a)
            )
          )
          (if (i32.or
                (f64.lt
                  (local.get $root)
                  (local.get $min_t_local)
                )
                (f64.lt
                  (global.get $max_t)
                  (local.get $root)
                )
              )
            (then
              (local.set $root
                (f64.div
                  (f64.add
                    (f64.neg 
                      (local.get $half_b)
                    )
                    (local.get $sqrtd)
                  )
                  (local.get $a)
                )
              )
              (if (i32.or
                    (f64.lt
                      (local.get $root)
                      (local.get $min_t_local)
                    )
                    (f64.lt
                      (global.get $max_t)
                      (local.get $root)
                    )
                  )
                (then
                  ;; there was a hit, but it was out of range
                  (local.set $hit_object (i32.const 0))
                  (br $determine_hit)
                )
              )
            )
          )
        )
      )

      ;; only bother setting these if there was a legitimate hit
      ;; copy sphere material data into HitRecord
      (local.set $out_material_type (local.get $sphere_material_type))
      (local.set $out_material_albedo_r (local.get $sphere_material_albedo_r))
      (local.set $out_material_albedo_g (local.get $sphere_material_albedo_g))
      (local.set $out_material_albedo_b (local.get $sphere_material_albedo_b))
      (local.set $out_material_fuzz (local.get $sphere_material_fuzz))
      (local.set $out_material_refraction_index (local.get $sphere_material_refraction_index))
      
      ;; determine hit location, normal data, etc.
      (local.set $out_hit_t (local.get $root))
      (local.set $out_hit_point_x 
        (local.set $out_hit_point_y
          (local.set $out_hit_point_z
            (call $ray_at
              (local.get $ray_origin_x)
              (local.get $ray_origin_y)
              (local.get $ray_origin_z)
              (local.get $ray_direction_x)
              (local.get $ray_direction_y)
              (local.get $ray_direction_z)
              (local.get $out_hit_t)
            )
          )
        )
      )
      (local.set $outward_normal_x
        (local.set $outward_normal_y
          (local.set $outward_normal_z
            (call $vec_div_constant
              (call $vec_sub_vec
                (local.get $out_hit_point_x)
                (local.get $out_hit_point_y)
                (local.get $out_hit_point_z)
                (local.get $sphere_center_x)
                (local.get $sphere_center_y)
                (local.get $sphere_center_z)
              )
              (local.get $sphere_radius)
            )
          )
        )
      )
      (local.set $out_front_face
        (f64.lt
          (call $vec_dot
            (local.get $ray_direction_x)
            (local.get $ray_direction_y)
            (local.get $ray_direction_z)
            (local.get $outward_normal_x)
            (local.get $outward_normal_y)
            (local.get $outward_normal_z)
          )
          (f64.const 0.0)
        )
      )

      (if (local.get $out_front_face) 
        (then
          (local.set $out_normal_x
            (local.get $outward_normal_x)
          )
          (local.set $out_normal_y
            (local.get $outward_normal_y)
          )
          (local.set $out_normal_z 
            (local.get $outward_normal_z)
          )
        )
        (else 
          (local.set $out_normal_x
            (f64.neg (local.get $outward_normal_x))
          )
          (local.set $out_normal_y
            (f64.neg (local.get $outward_normal_y))
          )
          (local.set $out_normal_z 
            (f64.neg (local.get $outward_normal_z))
          )
        )
      )
    )

    ;; return the HitRecord data
    (local.get $out_hit_point_x)
    (local.get $out_hit_point_y)
    (local.get $out_hit_point_z)
    (local.get $out_hit_t)
    (local.get $out_normal_x)
    (local.get $out_normal_y)
    (local.get $out_normal_z)
    (local.get $out_front_face)
    (local.get $out_material_type)
    (local.get $out_material_albedo_r)
    (local.get $out_material_albedo_g)
    (local.get $out_material_albedo_b)
    (local.get $out_material_fuzz)
    (local.get $out_material_refraction_index)
    
    ;; return on top of stack for checking if there was a hit
    ;; beore assigning the rest of the variables
    (local.get $hit_object)
  )

  ;; returns HitRecord
  (func $hit_world 
    (param $ray_origin_x f64)
    (param $ray_origin_y f64)
    (param $ray_origin_z f64)
    (param $ray_direction_x f64)
    (param $ray_direction_y f64)
    (param $ray_direction_z f64)

    ;; return HitRecord
    (result f64 f64 f64 f64 f64 f64 f64 i32 i32 f64 f64 f64 f64 f64 i32)

    ;; single HitRecord local data
    (local $hit_point_x f64)
    (local $hit_point_y f64)
    (local $hit_point_z f64)
    (local $hit_t f64)
    (local $normal_x f64)
    (local $normal_y f64)
    (local $normal_z f64)
    (local $front_face i32)
    (local $material_type i32)
    (local $material_albedo_r f64)
    (local $material_albedo_g f64)
    (local $material_albedo_b f64)
    (local $material_fuzz f64)
    (local $material_refraction_index f64)

    ;; $local_object_hit here refers to when testing 
    ;; against a single object (not all objects in the scene)
    (local $local_object_hit i32)

    ;; Sphere test data
    (local $test_sphere_center_x f64)
    (local $test_sphere_center_y f64)
    (local $test_sphere_center_z f64)
    (local $test_sphere_radius f64)
    (local $test_sphere_material_type i32)
    (local $test_sphere_material_albedo_r f64)
    (local $test_sphere_material_albedo_g f64)
    (local $test_sphere_material_albedo_b f64)
    (local $test_sphere_material_fuzz f64)
    (local $test_sphere_material_refraction_index f64)
    
    ;; data for looping through world objects
    (local $closest_so_far f64)
    (local $start_i i32) 
    (local $end_i i32) 
    (local $i i32)
    (local $step i32)

    ;; tested accross all objects 
    ;; $any_object_hit refers to any hits
    ;; accross all objects in the scene,
    ;; compared to $local_object_hit, which refers
    ;; to a single object being tested
    (local $any_object_hit i32)

    (local.set $test_sphere_center_x (f64.const 0.0))
    (local.set $test_sphere_center_y (f64.const 0.0))
    (local.set $test_sphere_center_z (f64.const -1.0))
    (local.set $test_sphere_radius (f64.const 0.5))
    (local.set $test_sphere_material_type (i32.const 0))
    (local.set $test_sphere_material_albedo_r (f64.const 0.3))
    (local.set $test_sphere_material_albedo_g (f64.const 0.3))
    (local.set $test_sphere_material_albedo_b (f64.const 0.4))
    (local.set $test_sphere_material_fuzz (f64.const 0.0))
    (local.set $test_sphere_material_refraction_index (f64.const 0.0))

    ;; initialize data for looping
    (local.set $closest_so_far (global.get $max_t))
    (local.set $start_i (global.get $object_list_ptr))
    (local.set $end_i (i32.add
      (global.get $object_list_ptr)
      (global.get $object_list_len)
    ))
    (local.set $step (global.get $object_size))
    (local.set $any_object_hit (i32.const 0))

    ;; iterate through objects in world
    (block $outer_loop_block 
      ;; inner loop - y coords
      (local.set $i (local.get $start_i))
      (loop $inner_loop
        (if (i32.lt_s (local.get $i) (local.get $end_i))
          (then

            (block $check_sphere_hit
              (call $hit_sphere
                ;; Sphere data
                (local.get $test_sphere_center_x)
                (local.get $test_sphere_center_y)
                (local.get $test_sphere_center_z)
                (local.get $test_sphere_radius)
                (local.get $test_sphere_material_type)
                (local.get $test_sphere_material_albedo_r)
                (local.get $test_sphere_material_albedo_g)
                (local.get $test_sphere_material_albedo_b)
                (local.get $test_sphere_material_fuzz)
                (local.get $test_sphere_material_refraction_index)
                ;; used to find the closest collission
                (local.get $closest_so_far)
                ;; Ray data
                (local.get $ray_origin_x)
                (local.get $ray_origin_y)
                (local.get $ray_origin_z)
                (local.get $ray_direction_x)
                (local.get $ray_direction_y)
                (local.get $ray_direction_z)
                ;; HitRecord data (in)
                (local.get $hit_point_x)
                (local.get $hit_point_y)
                (local.get $hit_point_z)
                (local.get $hit_t)
                (local.get $normal_x)
                (local.get $normal_y)
                (local.get $normal_z)
                (local.get $front_face)
                (local.get $material_type)
                (local.get $material_albedo_r)
                (local.get $material_albedo_g)
                (local.get $material_albedo_b)
                (local.get $material_fuzz)
                (local.get $material_refraction_index)
              )

              ;; pop this value off the stack first to check
              ;; if anything was hit before assigning variables
              (local.set $local_object_hit)

              ;; if not hit occurred, do not overwrite previous hit data
              (if (local.get $local_object_hit)
                (then
                  (br $check_sphere_hit)
                )
              )

              ;; pop values off of stack from $hit_sphere
              ;; and assign hit_record data
              (local.set $hit_point_x
                (local.set $hit_point_y
                  (local.set $hit_point_z
                    (local.set $hit_t
                      (local.set $normal_x
                        (local.set $normal_y
                          (local.set $normal_z
                            (local.set $front_face
                              (local.set $material_type
                                (local.set $material_albedo_r
                                  (local.set $material_albedo_g
                                    (local.set $material_albedo_b
                                      (local.set $material_fuzz
                                        (local.set $material_refraction_index)
                                      )
                                    )
                                  )
                                )
                              )
                            )
                          )
                        )
                      )
                    )
                  )
                )
              ) 
              (local.set $any_object_hit (i32.const 1))
              (local.set $closest_so_far (local.get $hit_t))
            )
            
            (local.set $i (i32.add (local.get $i) (local.get $step)))
            ;; return to beginning of loop
            (br $inner_loop)
          )
          ;; exit loop
          (else (br $outer_loop_block))
        )
      )
    )

    ;; return HitRecord data
    (local.get $hit_point_x)
    (local.get $hit_point_y)
    (local.get $hit_point_z)
    (local.get $hit_t)
    (local.get $normal_x)
    (local.get $normal_y)
    (local.get $normal_z)
    (local.get $front_face)
    (local.get $material_type)
    (local.get $material_albedo_r)
    (local.get $material_albedo_g)
    (local.get $material_albedo_b)
    (local.get $material_fuzz)
    (local.get $material_refraction_index)

    ;; return if any object in the scene was hit
    (local.get $any_object_hit)
  )

  ;; accepts ray and returns the color that ray should be
  ;; in rgb of range 0->1
  (func $ray_color
    (param $ray_origin_x f64)
    (param $ray_origin_y f64)
    (param $ray_origin_z f64)
    (param $ray_direction_x f64)
    (param $ray_direction_y f64)
    (param $ray_direction_z f64)
    (result f64 f64 f64)

    (local $color_r f64)
    (local $color_g f64)
    (local $color_b f64)

    ;; HitRecord data
    (local $hit_point_x f64)
    (local $hit_point_y f64)
    (local $hit_point_z f64)
    (local $hit_t f64)
    (local $normal_x f64)
    (local $normal_y f64)
    (local $normal_z f64)
    (local $front_face i32)
    (local $material_type i32)
    (local $material_albedo_r f64)
    (local $material_albedo_g f64)
    (local $material_albedo_b f64)
    (local $material_fuzz f64)
    (local $material_refraction_index f64)

    (local $any_object_hit i32)

    ;; each ray starts out at full brightness
    (local.set $color_r (f64.const 1.0))
    (local.set $color_g (f64.const 1.0))
    (local.set $color_b (f64.const 1.0))

    ;; no hit, return sky background gradient
    (local.set $color_r
      (local.set $color_g
        (local.set $color_b
          (call $vec_mul_vec
            (local.get $color_r)
            (local.get $color_g)
            (local.get $color_b)
            (call $background
              (local.get $ray_origin_x)
              (local.get $ray_origin_y)
              (local.get $ray_origin_z)
              (local.get $ray_direction_x)
              (local.get $ray_direction_y)
              (local.get $ray_direction_z)
            )
          )
        )
      )
    )

    (local.set $hit_point_x
      (local.set $hit_point_y
        (local.set $hit_point_z
          (local.set $hit_t
            (local.set $normal_x
              (local.set $normal_y
                (local.set $normal_z
                  (local.set $front_face
                    (local.set $material_type
                      (local.set $material_albedo_r
                        (local.set $material_albedo_g
                          (local.set $material_albedo_b
                            (local.set $material_fuzz
                              (local.set $material_refraction_index
                                (local.set $any_object_hit
                                  (call $hit_world
                                    (local.get $ray_origin_x)
                                    (local.get $ray_origin_y)
                                    (local.get $ray_origin_z)
                                    (local.get $ray_direction_x)
                                    (local.get $ray_direction_y)
                                    (local.get $ray_direction_z)
                                  )
                                )
                              )
                            )
                          )
                        )
                      )
                    )
                  )
                )
              )
            )
          )
        )
      )
    )

    (if (i32.eq (local.get $any_object_hit) (i32.const 0))
      ;; not hit detected: show background
      (then 
        (return
          (local.get $color_r)
          (local.get $color_g)
          (local.get $color_b)
        )
      )
    )

    ;; hit detected: show object
    ;; display's the circle's normals for now
    ;; todo - replace with scattering calculations
    (f64.mul
      (f64.const 0.5)
      (f64.add
        (local.get $normal_x)
        (f64.const 1.0)
      )
    )
    (f64.mul
      (f64.const 0.5)
      (f64.add
        (local.get $normal_y)
        (f64.const 1.0)
      )
    )
    (f64.mul
      (f64.const 0.5)
      (f64.add
        (local.get $normal_z)
        (f64.const 1.0)
      )
    )
  )

  ;; converts f64 color in range 0.0->1.0 into u8 color 0-255
  (func $color_f64_to_u8
    (param $r f64)
    (param $g f64)
    (param $b f64)
    (result i32 i32 i32)

    (i32.trunc_sat_f64_u
      (f64.mul
        (local.get $r)
        (f64.const 255)
      )
    )
     (i32.trunc_sat_f64_u
      (f64.mul
        (local.get $g)
        (f64.const 255)
      )
    )
     (i32.trunc_sat_f64_u
      (f64.mul
        (local.get $b)
        (f64.const 255)
      )
    )
  )
  
  ;; s & t should map from 0.0 -> 1.0
  ;; s 0->1 maps from left to right on the canvas
  ;; t 0->1 maps from bottom to top on the canvas
  (func $get_pixel_color 
    (param $s f64) 
    (param $t f64)
    (result i32 i32 i32 i32)

    (local $ray_origin_x f64)
    (local $ray_origin_y f64)
    (local $ray_origin_z f64)

    (local $ray_direction_x f64)
    (local $ray_direction_y f64)
    (local $ray_direction_z f64)

    (local $color_r f64)
    (local $color_g f64)
    (local $color_b f64)
    
    ;; wasm-equivalent of desctructuring assignment
    ;; pops multiple values off the stack
    ;; and assigns them to local variables
    (local.set $ray_origin_x
      (local.set $ray_origin_y
        (local.set $ray_origin_z
          (local.set $ray_direction_x
            (local.set $ray_direction_y
              (local.set $ray_direction_z
                (call $get_ray_from_camera
                  (local.get $s)
                  (local.get $t)
                )
              )
            )
          )
        )
      )
    )

    ;; get color that each ray returns
    (local.set $color_r
      (local.set $color_g
        (local.set $color_b
          (call $ray_color
            (local.get $ray_origin_x)
            (local.get $ray_origin_y)
            (local.get $ray_origin_z)
            (local.get $ray_direction_x)
            (local.get $ray_direction_y)
            (local.get $ray_direction_z)
          )
        )
      )
    )

    ;; todo - scale color by number of samples

    ;; gamma correction
    (local.set $color_r 
      (f64.sqrt (local.get $color_r))
    )
    (local.set $color_g 
      (f64.sqrt (local.get $color_g))
    )
    (local.set $color_b 
      (f64.sqrt (local.get $color_b))
    )
    
    ;; convert 0->1 color to 0->255
    (call $color_f64_to_u8
      (local.get $color_r)
      (local.get $color_g)
      (local.get $color_b)
    )
    (i32.const 255)
  )


  (func $render_to_internal_buffer
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
                    (f64.sub
                      ;; flip y axis, since canvas is upside down
                      ;; compared to normal rendering conventions
                      (f64.const 1.0)
                      (f64.div
                        (f64.convert_i32_u (local.get $j))
                        (f64.convert_i32_u (global.get $canvas_height))
                      )
                    )
                  )

                  
                  (call $draw_pixel 
                    ;; supplies the pixel coordinates
                    (local.get $i)
                    (local.get $j)
                    ;; supplies the color for that pixel
                    (call $get_pixel_color
                      (local.get $s)
                      (local.get $t)
                    )
                  )
                  
                  ;; debugging colors / pixels
                  ;; (call $log_2 (local.get $i) (local.get $j))
                  ;; (call $log_float_2 (local.get $s) (local.get $t))
                  ;; (call $get_pixel_color
                  ;;   (local.get $s)
                  ;;   (local.get $t)
                  ;; )
                  ;; (call $log_4)
                  ;; (call $log (i32.const 11111111))
                  
                  (local.set $j (i32.add (local.get $j) (local.get $step)))
                  ;; return to beginning of loop
                  (br $inner_loop)
                )
                ;; exit loop
                (else (br $inner_block))
              )
            )
          )

          
          (local.set $i (i32.add (local.get $i) (local.get $step)))
          (br $outer_loop)
        )
        (else return)
      )
    )
  )

  (func $add_object_to_world
    (param $sphere_center_x f64)
    (param $sphere_center_y f64)
    (param $sphere_center_z f64)
    (param $sphere_radius f64)
    (param $sphere_material_type i32)
    (param $sphere_material_albedo_r f64)
    (param $sphere_material_albedo_g f64)
    (param $sphere_material_albedo_b f64)
    (param $sphere_material_fuzz f64)
    (param $sphere_material_refraction_index f64)

    (local $new_memory_address i32)

    (local.set $new_memory_address
      (i32.add
        (global.get $object_list_ptr)
        (global.get $object_list_len)
      )
    )

    (f64.store
      offset=0
      (local.get $new_memory_address)
      (local.get $sphere_center_x)
    )
    (f64.store
      offset=8
      (local.get $new_memory_address)
      (local.get $sphere_center_y)
    )
    (f64.store
      offset=16
      (local.get $new_memory_address)
      (local.get $sphere_center_z)
    )
    (f64.store
      offset=24
      (local.get $new_memory_address)
      (local.get $sphere_radius)
    )
    (i32.store
      offset=32
      (local.get $new_memory_address)
      (local.get $sphere_material_type)
    )
    (f64.store
      offset=36
      (local.get $new_memory_address)
      (local.get $sphere_material_albedo_r)
    )
    (f64.store
      offset=44
      (local.get $new_memory_address)
      (local.get $sphere_material_albedo_g)
    )
    (f64.store
      offset=52
      (local.get $new_memory_address)
      (local.get $sphere_material_albedo_b)
    )
    (f64.store
      offset=60
      (local.get $new_memory_address)
      (local.get $sphere_material_fuzz)
    )
    (f64.store
      offset=68
      (local.get $new_memory_address)
      (local.get $sphere_material_refraction_index)
    )

    ;; increment length of list
    (global.set $object_list_len
      (i32.add
        (global.get $object_list_len)
        (global.get $object_size)
      )
    )
  )

  ;; i = index of the object. 
  ;; i.e. 0 = first object, 1 = 2nd object, etc.
  (func $get_object_from_memory (param $i i32)
    (result f64 f64 f64 f64 i32 f64 f64 f64 f64 f64)
    (local $local_ptr i32)

    ;; can't index from empty list
    (if (i32.eqz (global.get $object_list_len))
      (then
        (unreachable)
      )
    )

    (local.set $local_ptr
      (i32.add 
        (global.get $object_list_ptr)
        (i32.mul
          (local.get $i)
          (global.get $object_size)
        )
      )
    )

    (f64.load
      offset=0
      (local.get $local_ptr)
    )
    (f64.load
      offset=8
      (local.get $local_ptr)
    )
    (f64.load
      offset=16
      (local.get $local_ptr)
    )
    (f64.load
      offset=24
      (local.get $local_ptr)
    )
    (i32.load
      offset=32
      (local.get $local_ptr)
    )
    (f64.load
      offset=36
      (local.get $local_ptr)
    )
    (f64.load
      offset=44
      (local.get $local_ptr)
    )
    (f64.load
      offset=52
      (local.get $local_ptr)
    )
    (f64.load
      offset=60
      (local.get $local_ptr)
    )
    (f64.load
      offset=68
      (local.get $local_ptr)
    )
  )

  (func $test_extracting_info
    (local $test_sphere_center_x f64)
    (local $test_sphere_center_y f64)
    (local $test_sphere_center_z f64)
    (local $test_sphere_radius f64)
    (local $test_sphere_material_type i32)
    (local $test_sphere_material_albedo_r f64)
    (local $test_sphere_material_albedo_g f64)
    (local $test_sphere_material_albedo_b f64)
    (local $test_sphere_material_fuzz f64)
    (local $test_sphere_material_refraction_index f64)

    
    
    (call $log_float 
      (local.get $test_sphere_center_x)
    )
    (call $log_float 
      (local.get $test_sphere_center_y)
    )
    (call $log_float 
      (local.get $test_sphere_center_z)
    )
    (call $log_float 
      (local.get $test_sphere_radius)
    )
    (call $log
      (local.get $test_sphere_material_type)
    )
    (call $log_float 
      (local.get $test_sphere_material_albedo_r)
    )
    (call $log_float 
      (local.get $test_sphere_material_albedo_g)
    )
    (call $log_float 
      (local.get $test_sphere_material_albedo_b)
    )
    (call $log_float 
      (local.get $test_sphere_material_fuzz)
    )
    (call $log_float 
      (local.get $test_sphere_material_refraction_index)
    )
    (call $log (i32.const 111111111))

    (local.set $test_sphere_center_x
      (local.set $test_sphere_center_y
        (local.set $test_sphere_center_z
          (local.set $test_sphere_radius
            (local.set $test_sphere_material_type
              (local.set $test_sphere_material_albedo_r
                (local.set $test_sphere_material_albedo_g
                  (local.set $test_sphere_material_albedo_b
                    (local.set $test_sphere_material_fuzz
                      (local.set $test_sphere_material_refraction_index
                        (call $get_object_from_memory (i32.const 1))
                      )
                    )
                  )
                )
              )
            )
          )
        )
      )
    )
    
    (call $log_float 
      (local.get $test_sphere_center_x)
    )
    (call $log_float 
      (local.get $test_sphere_center_y)
    )
    (call $log_float 
      (local.get $test_sphere_center_z)
    )
    (call $log_float 
      (local.get $test_sphere_radius)
    )
    (call $log
      (local.get $test_sphere_material_type)
    )
    (call $log_float 
      (local.get $test_sphere_material_albedo_r)
    )
    (call $log_float 
      (local.get $test_sphere_material_albedo_g)
    )
    (call $log_float 
      (local.get $test_sphere_material_albedo_b)
    )
    (call $log_float 
      (local.get $test_sphere_material_fuzz)
    )
    (call $log_float 
      (local.get $test_sphere_material_refraction_index)
    )
    (call $log (i32.const 111111111))
  )

  (func $generate_default_objects_in_world
    ;; sphere data
    (local $sphere_center_x f64)
    (local $sphere_center_y f64)
    (local $sphere_center_z f64)
    (local $sphere_radius f64)
    (local $sphere_material_type i32)
    (local $sphere_material_albedo_r f64)
    (local $sphere_material_albedo_g f64)
    (local $sphere_material_albedo_b f64)
    (local $sphere_material_fuzz f64)
    (local $sphere_material_refraction_index f64)
    
    ;; circle in front
    (local.set $sphere_center_x (f64.const 0.0))
    (local.set $sphere_center_y (f64.const 0.0))
    (local.set $sphere_center_z (f64.const -1.0))
    (local.set $sphere_radius (f64.const 0.5))
    (local.set $sphere_material_type (i32.const 0))
    (local.set $sphere_material_albedo_r (f64.const 0.3))
    (local.set $sphere_material_albedo_g (f64.const 0.3))
    (local.set $sphere_material_albedo_b (f64.const 0.4))
    (local.set $sphere_material_fuzz (f64.const 0.0))
    (local.set $sphere_material_refraction_index (f64.const 0.0))

    (call $add_object_to_world
      (local.get $sphere_center_x)
      (local.get $sphere_center_y)
      (local.get $sphere_center_z)
      (local.get $sphere_radius)
      (local.get $sphere_material_type)
      (local.get $sphere_material_albedo_r)
      (local.get $sphere_material_albedo_g)
      (local.get $sphere_material_albedo_b)
      (local.get $sphere_material_fuzz)
      (local.get $sphere_material_refraction_index)
    )

    ;; circle below (ground)
    (local.set $sphere_center_x (f64.const 0.0))
    (local.set $sphere_center_y (f64.const -100.5))
    (local.set $sphere_center_z (f64.const -1.0))
    (local.set $sphere_radius (f64.const 100.0))
    (local.set $sphere_material_type (i32.const 1))
    (local.set $sphere_material_albedo_r (f64.const 0.75))
    (local.set $sphere_material_albedo_g (f64.const 0.6))
    (local.set $sphere_material_albedo_b (f64.const 0.5))
    (local.set $sphere_material_fuzz (f64.const 0.0))
    (local.set $sphere_material_refraction_index (f64.const 0.0))

    (call $add_object_to_world
      (local.get $sphere_center_x)
      (local.get $sphere_center_y)
      (local.get $sphere_center_z)
      (local.get $sphere_radius)
      (local.get $sphere_material_type)
      (local.get $sphere_material_albedo_r)
      (local.get $sphere_material_albedo_g)
      (local.get $sphere_material_albedo_b)
      (local.get $sphere_material_fuzz)
      (local.get $sphere_material_refraction_index)
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
    (call $update_camera_values)
  )
  
  ;; called on each tick to update all internal state
  (func (export "tick")
    ;; (call $render_to_internal_buffer)
    (call $test_extracting_info)
  )
  
  (func (export "init") 
    (param $initial_canvas_width i32) 
    (param $initial_canvas_height i32)

    (call $generate_default_objects_in_world)

    ;; synchronize window, canvas size, and camera state
    (call $sync_viewport 
      (local.get $initial_canvas_width) 
      (local.get $initial_canvas_height)
    )
  )
)