(module
  ;; mock function that increments state in JS when called
  (import "js" "fn" (func $fn))

  ;; calls imported function in argument is less than a given number
  (func (export "call_if_less_than") (param $num i32) (param $comparison i32)
    (block $check
      local.get $num
      local.get $comparison
      i32.ge_s
      
      ;; if num is greater than or equal to 10, break
      if
       ;; "br" inside a block skips to the end of that block
      br $check
      ;; ends a `block`, `loop`, `if`, or `else` when not using s-expession syntax
      end

      
      ;; if less than, call function
      call $fn
    )
  )

  ;; calls imported function in argument is greater than a given number
  ;; practice organizing code in different ways:
  (func (export "call_if_greater_than") (param $num i32) (param $comparison i32)
    ;; these are all equivalent expressions: ----------------------------------------

    ;; (if (i32.gt_s (local.get $num) (local.get $comparison))
    ;;   (then call $fn)
    ;;   (else nop) ;; nop doesn't do anything
    ;; )

    ;; (if (i32.gt_s (local.get $num) (local.get $comparison))
    ;;   (then call $fn)
    ;;   (else)
    ;; )

    ;; (if (i32.gt_s (local.get $num) (local.get $comparison))
    ;;   (then call $fn)
    ;; )

    ;; (i32.gt_s (local.get $num) (local.get $comparison))
    ;; (if
    ;;   (then call $fn)
    ;; )

    ;; (if (i32.gt_s (local.get $num) (local.get $comparison))
    ;;   (then 
    ;;     call $fn
    ;;     return
    ;;   )
    ;;   (else return)
    ;; )
    ;; ;; can be used to denote when some code should not be reachable
    ;; ;; throws an unrecoverable error if this code is ever actually reached
    ;; unreachable

    local.get $num
    local.get $comparison
    i32.gt_s
    if
    call $fn
    end
  )

  (func (export "fibonacci") (param $n i32) (result i32)
    (local $i i32)
    (local $a i32)
    (local $b i32)
    (local $c i32)

    (local.set $a (i32.const 0))
    (local.set $b (i32.const 1))

    ;; if n === 0, return 0
    local.get $n
    i32.eqz
    if
      (return (i32.const 0))
    end

    ;; loop until reaching desired index
    i32.const 2
    local.set $i
    loop $loop
      local.get $i
      local.get $n
      i32.lt_s
      if $if
        (local.set $c (i32.add (local.get $a) (local.get $b)))
        (local.set $a (local.get $b))
        (local.set $b (local.get $c))
        (local.set $i (i32.add (local.get $i) (i32.const 1)))
        (br $loop) ;; "br" loops back to beginning of loop
      end $if
    end $loop
    
    local.get $a
    local.get $b
    i32.add
  )
)