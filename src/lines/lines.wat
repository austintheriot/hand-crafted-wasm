(module
  ;; IMPORTS
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  (import "console" "log" (func $log (param i32)))
  (import "console" "log" (func $log_float (param f64)))

  ;; MEMORY
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  (memory $memory (export "memory") 10)

  ;; canvas data (no memory offset)
  (global $WIDTH (export "WIDTH") i32 (i32.const 255))
  (global $HEIGHT (export "HEIGHT") i32 (i32.const 255))
  (global $NUM_PIXELS (mut i32) (i32.const 0))
  (global $BYTES_PER_PX i32 (i32.const 4))
  (global $MEM_NOP i32 (i32.const -1))
  (global $CANVAS_MEMORY_OFFSET (export "CANVAS_MEMORY_OFFSET") i32 (i32.const 0)) 
  (global $CANVAS_MEMORY_LENGTH (export "CANVAS_MEMORY_LENGTH") (mut i32) (i32.const 0))

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

  ;; set canvas color as opaque white
  (func $clear_canvas
    (memory.fill
      (global.get $CANVAS_MEMORY_OFFSET)
      (i32.const 0) 
      (i32.add (global.get $CANVAS_MEMORY_OFFSET) (global.get $CANVAS_MEMORY_LENGTH))
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
  )

  ;; EXTERNAL FUNCTIONS
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  ;; update state on every tick
  (func (export "update")
    ;; clear canvas
    (call $clear_canvas)

    (call $draw_line
      (i32.const 17)
      (i32.const 21)
      (i32.const 240)
      (i32.const 253)
      (i32.const 0xff)
      (i32.const 0)
      (i32.const 0)
      (i32.const 0xff)
    )

    (call $draw_line
      (i32.const 240)
      (i32.const 253)
      (i32.const 13)
      (i32.const 240)
      (i32.const 0xff)
      (i32.const 0)
      (i32.const 0)
      (i32.const 0xff)
    )

    (call $draw_line
      (i32.const 17)
      (i32.const 21)
      (i32.const 13)
      (i32.const 240)
      (i32.const 0xff)
      (i32.const 0)
      (i32.const 0)
      (i32.const 0xff)
    )
  )

  ;; initilize state when wasm module is instantiated
  (start $init)
)