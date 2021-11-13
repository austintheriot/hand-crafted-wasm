(module
  ;; for debugging
  (import "console" "log" (func $log (param i32)))

  ;; wasm is little-endian: numbers appear in the same order in which we'd normally write them
  ;; i.e. 6 === 110
  (func (export "shift_left") (param $num i32) (param $shift i32) (result i32)
    local.get $num
    local.get $shift
    i32.shl
  )

  (func (export "get_bit") (param $num i32) (param $i i32) (result i32)
    (i32.eq
      (i32.and ;; convert number to lone 1 or 0
        (i32.shr_u (local.get $num) (local.get $i)) ;; move the digit in question to front
        (i32.const 1)
      )
      (i32.const 1)
    )
  )

   (func (export "set_bit") (param $num i32) (param $i i32) (param $bit i32) (result i32)
    ;; convert input bit to 1 or 0
    (local.set $bit 
      (i32.and 
        (local.get $bit) 
        (i32.const 1)
      )
    )
    ;; move input bit over to the intended index
    (local.set $bit 
      (i32.shl 
        (local.get $bit) 
        (local.get $i)
      )
    )
    
    ;; clear bit with mask
    (local.set $num 
      (i32.and 
        (local.get $num) 
        ;; all ones with a hole at $i (11101), etc.
        ;; n ^ all_ones === ~n
        (i32.xor 
          (i32.shl 
              (i32.const 1) 
              (local.get $i)
          )
          ;; all ones (11111... etc.)
          (i32.const -1) 
        )
      )
    )

    ;; set bit
    (i32.or 
      (local.get $num) 
      (local.get $bit)
    )
  )
)