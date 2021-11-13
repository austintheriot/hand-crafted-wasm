(module
  ;; add two floats together
  (func $add (param $num1 f64) (param $num2 f64) (result f64)
    local.get $num1
    local.get $num2
    f64.add
  )

  ;; same thing, using nested syntax
  (func $add2 (param $num1 f64) (param $num2 f64) (result f64)
    (f64.add (local.get $num1)(local.get $num2))
  )

  ;; same thing, inlined export syntax shorthand
  (func (export "add3") (param $num1 f64) (param $num2 f64) (result f64)
    (f64.add (local.get $num1)(local.get $num2))
  )

  ;; calling other function
  (func (export "add4") (param $num1 f64) (param $num2 f64) (result f64)
    local.get $num1
    local.get $num2
    call $add
  )

  (export "add" (func $add))
  (export "add2" (func $add2))
)