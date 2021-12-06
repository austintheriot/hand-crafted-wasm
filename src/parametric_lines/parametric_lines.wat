(module
  ;; IMPORTS
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  (import "Math" "sin" (func $sin (param f64) (result f64)))
  (import "Math" "cos" (func $cos (param f64) (result f64)))
  (global $PI (import "Math" "PI") f64)
  (import "console" "log" (func $log (param i32)))
  (import "console" "log" (func $log_float (param f64)))

  ;; MEMORY
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  (memory $memory (export "memory") 2000)

  ;; canvas data (no memory offset)
  (global $WIDTH (export "WIDTH") i32 (i32.const 2500))
  (global $HEIGHT (export "HEIGHT") i32 (i32.const 2500))
  (global $NUM_PIXELS (mut i32) (i32.const 0))
  (global $BYTES_PER_PX i32 (i32.const 4))
  (global $MEM_NOP i32 (i32.const -1))
  (global $T (mut f64) (f64.const 0))
  (global $CANVAS_MEMORY_OFFSET (export "CANVAS_MEMORY_OFFSET") i32 (i32.const 0)) 
  (global $CANVAS_MEMORY_LENGTH (export "CANVAS_MEMORY_LENGTH") (mut i32) (i32.const 0))

  (global $TWO_PI (mut f64) (f64.const 0))

  ;; INTERNAL FUNCTIONS
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
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

    global.get $WIDTH
    local.get $y
    i32.mul
    local.get $x
    i32.add
    global.get $BYTES_PER_PX
    i32.mul
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

  (func $draw_pixel 
    (param $x i32) (param $y i32) 
    (param $r i32) (param $g i32) (param $b i32) (param $a i32)
    (local $canvas_mem_index i32)

    (local.set $canvas_mem_index 
      (call $canvas_coords_to_canvas_mem_index 
        (local.get $x)
        (local.get $y)
      )
    )

    ;; ignore coordinates that fall outside of canvas range
    (if (i32.eq (local.get $canvas_mem_index) (global.get $MEM_NOP))
      (then return)
    )
    
    ;; add colors from previous pixels together (max out at 0xff for each color band)
    (i32.store8
      offset=0
      (local.get $canvas_mem_index)
      (local.get $r)
    )
    (i32.store8
      offset=1
      (local.get $canvas_mem_index)
      (local.get $g)
    )
    (i32.store8
      offset=2
      (local.get $canvas_mem_index)
      (local.get $b)
    )
    (i32.store8
      offset=3
      (local.get $canvas_mem_index)
      (local.get $a)
    )
  )

  ;; prepare state
  (func $init
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

    global.get $PI
    f64.const 2
    f64.mul
    global.set $TWO_PI

    (call $clear_canvas)
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

  ;; EXTERNAL FUNCTIONS
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  ;; update state on every tick
  (func (export "tick")
    (local $x0 i32)
    (local $y0 i32)
    (local $x1 i32)
    (local $y1 i32)
    (local $i i32)

    (loop $loop
      (if 
        (i32.lt_s (local.get $i) (i32.const 10000))
        (then

          (global.set $T (f64.add (global.get $T) (f64.const 0.001)))

          (local.set $x0
            (i32.trunc_sat_f64_u
              (call $map
                (f64.add
                  (call $cos 
                    (f64.mul
                      (global.get $T)
                      (f64.const 1.001)
                    )
                  )
                  (call $sin 
                    (f64.mul
                      (global.get $T)
                      (f64.const 1.002)
                    )
                  )
                )
                (f64.const -2)
                (f64.const 2)
                (f64.const 0)
                (f64.convert_i32_u (global.get $WIDTH))
              )
            )
          )

          (local.set $y0
            (i32.trunc_sat_f64_u
              (call $map
              (f64.add
                  (call $cos 
                    (f64.mul
                      (global.get $T)
                      (f64.const 1.003)
                    )
                  )
                  (call $sin 
                    (f64.mul
                      (global.get $T)
                      (f64.const 1.004)
                    )
                  )
                )
                (f64.const -2)
                (f64.const 2)
                (f64.const 0)
                (f64.convert_i32_u (global.get $HEIGHT))
              )
            )
          )

          (call $draw_pixel
            (local.get $x0)
            (local.get $y0)
            (i32.const 0xff)
            (i32.const 0xff)
            (i32.const 0xff)
            (i32.const 0xff)
          )

          (local.set $i (i32.add (local.get $i) (i32.const 1)))
          (br $loop)
        )
      )
    )

    

    ;; (local.set $x1
    ;;   (i32.trunc_sat_f64_u
    ;;     (call $map
    ;;       (f64.add
    ;;         (call $sin (f64.add (global.get $T) (global.get $PI)))
    ;;         (call $cos (f64.add (global.get $T) (global.get $PI)))
    ;;       )
    ;;       (f64.const -2)
    ;;       (f64.const 2)
    ;;       (f64.const 0)
    ;;       (f64.convert_i32_u (global.get $WIDTH))
    ;;     )
    ;;   )
    ;; )

    ;; (local.set $y1
    ;;   (i32.trunc_sat_f64_u
    ;;     (call $map
    ;;       (call $sin (f64.add (global.get $T) (global.get $PI)))
    ;;       (f64.const -1)
    ;;       (f64.const 1)
    ;;       (f64.const 0)
    ;;       (f64.convert_i32_u (global.get $HEIGHT))
    ;;     )
    ;;   )
    ;; )

    ;; clear canvas
    ;; (call $clear_canvas)

    ;; (call $draw_line
    ;;   (local.get $x0)
    ;;   (local.get $y0)
    ;;   (i32.const 0xff)
    ;;   (i32.const 0xff)
    ;;   (i32.const 0xff)
    ;;   (i32.const 0xff)
    ;; )
  )

  ;; initilize state when wasm module is instantiated
  (start $init)
)