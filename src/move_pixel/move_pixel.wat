(module
  ;; for debugging
  (import "console" "log" (func $log_js (param i32)))

  ;; pixel data for drawing to canvas
  ;; initialize pixels as rgba(u8 u8 u8 u8) values
  (memory (export "memory") 1)
  
  ;; constant globals
  (global $HEIGHT (export "HEIGHT") i32 (i32.const 32))
  (global $WIDTH (export "WIDTH") i32 (i32.const 32))
  (global $BPP (export "BPP") i32 (i32.const 4)) ;; bytes per pixel
  (global $CANVAS_MEMORY_OFFSET (export "CANVAS_MEMORY_OFFSET") i32 (i32.const 0))
  (global $CANVAS_MEMORY_LENGTH (export "CANVAS_MEMORY_LENGTH") i32 (i32.const 4096)) ;; WIDTH * HEIGHT * BPP

  ;; mutable globals
  (global $active_i (mut i32) (i32.const 0))

  (func $get_i_from_coords (export "get_i_from_coords") (param $x i32) (param $y i32) (result i32)
    ;; transform any out of bounds input to be within the bounds of the canvas
    (if (i32.lt_s (local.get $x) (i32.const 0)) 
      (then (local.set $x (i32.const 0)))
    )
    (if (i32.gt_s (local.get $x) (i32.sub (global.get $WIDTH) (i32.const 1))) 
      (then 
        (local.set $x 
          (i32.sub 
            (global.get $WIDTH) 
            (i32.const 1)
          )
        )
      )
    )
    (if (i32.lt_s (local.get $y) (i32.const 0)) 
      (then (local.set $y (i32.const 0)))
    )
    (if (i32.gt_s (local.get $y) (i32.sub (global.get $HEIGHT) (i32.const 1))) 
      (then 
        (local.set $y 
          (i32.sub 
            (global.get $HEIGHT) 
            (i32.const 1)
          )
        )
      )
    )

    ;; (y * width) + x
    global.get $WIDTH
    local.get $y
    i32.mul
    local.get $x
    i32.add
    return
  )

  (func $draw_cell (export "draw_cell") (param $i i32) (param $active i32)
    (local $r i32)
    (local $g i32)
    (local $b i32)

    ;; which color to draw cell
    (if (local.get $active)
      (then 
        (local.set $r (i32.const 0x88))
        (local.set $g (i32.const 0x88))
        (local.set $b (i32.const 0xFF))
      )
      (else 
        (local.set $r (i32.const 0))
        (local.set $g (i32.const 0))
        (local.set $b (i32.const 0))
      )
    )

    (i32.store8 (local.get $i) (local.get $r))
    (i32.store8 (i32.add (local.get $i) (i32.const 1)) (local.get $g))
    (i32.store8 (i32.add (local.get $i) (i32.const 2)) (local.get $b))
    (i32.store8 (i32.add (local.get $i) (i32.const 3)) (i32.const 0xFF))
  )

  ;; increment the active_i over by the width of one pixel
  (func $inc_px (param $i i32) (result i32)
    (i32.add 
        (local.get $i) 
        (global.get $BPP)
    )
  )

  (func $reset_active_i
    (global.set $active_i (i32.const 0))
  )

  (func $i_is_at_final_position (param $i i32) (result i32)
    (i32.ge_s 
      (local.get $i) 
      (i32.sub 
        (global.get $CANVAS_MEMORY_LENGTH) 
        (global.get $BPP)
      )
    )
  )
  
  ;; loop through canvas pixels and set all pixels to inactive
  (func $init_canvas_data (export "init_canvas_data")
    (local $i i32)
    (local.set $i (i32.const 0))

    (loop $loop
      (call $draw_cell (local.get $i) (i32.const 0))

      (if (call $i_is_at_final_position (local.get $i))
        (then 
          return
        )
        (else 
          (local.set $i (call $inc_px (local.get $i)))
          br $loop
        )
      )
    )
  )

  (func $update (export "update")
    ;; update active_i in canvas data as NOT active
    (call $draw_cell (global.get $active_i) (i32.const 0))

    ;; increment active_i
    (if (call $i_is_at_final_position (global.get $active_i))
        (then call $reset_active_i)
        (else (global.set $active_i (call $inc_px (global.get $active_i))))
    )

    ;; update the new active_i in canvas data as ACTIVE 
    (call $draw_cell (global.get $active_i) (i32.const 1))
  )
)