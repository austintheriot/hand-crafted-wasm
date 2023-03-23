(module
  ;; IMPORTS
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  (import "Math" "random" (func $random (result f64)))
  (import "console" "log" (func $log (param i32)))
  (import "console" "log" (func $log_float (param f64)))

  ;; update actual canvas dimensions based on inner aspect-ratio calculations
  (import "canvas" "updateCanvasDimensions" (func $update_canvas_dimensions (param $width i32) (param $height i32)))

  ;; MEMORY
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  (memory $memory (export "memory") 2000)

  ;; canvas data
  (global $canvas_width (export "canvas_width") (mut i32) (i32.const 0))
  (global $canvas_height (export "canvas_height") (mut i32) (i32.const 0))
  ;; largest possible size the canvas can be in any one direction in pixels
  (global $max_dimension i32 (i32.const 100))
  ;; 100w * 100h * 4 bytes per pixel = 0-40,000

  ;; rendering constants
  ;; (global $width f64 (f64.const 0))
  ;; (global $height f64 (f64.const 0))
  ;; (global $now f64 (f64.const 0))

  ;; EXPORTS
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  
  ;; save the windows actual size in pixels in wasm memory
  (func $viewport (export "viewport") 
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
  (func (export "update"))
  
  (func $init 
    (export "init") 
    (param $initial_canvas_width i32) 
    (param $initial_canvas_height i32)

    ;; synchronize window && canvas size with internal state
    (call $viewport 
      (local.get $initial_canvas_width) 
      (local.get $initial_canvas_height)
    )
  )
)