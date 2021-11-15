(module
  (memory (export "memory") 1)
  (type $OneParameter (func (param i32) (result i32))) 
  (type $TwoParameters (func (param i32) (param i32) (result i32))) 

  (table funcref (elem $t0 $t1 $t2 $u0 $u1 $u2))

  ;; identical implementation, different syntax:
  ;; (table 6 funcref)
  ;; (elem (i32.const 0) $t0 $t1 $t2 $u0 $u1 $u2)
  
  (func $t0 (param i32) (result i32) (i32.add (local.get 0) (i32.const 0)))
  (func $t1 (param i32) (result i32) (i32.add (local.get 0) (i32.const 1)))
  (func $t2 (param i32) (result i32) (i32.add (local.get 0) (i32.const 2)))
  (func $u0 (param $n0 i32) (param $n1 i32) (result i32) (i32.add (local.get 0) (i32.add (local.get 1) (i32.const 0))))
  (func $u1 (param $n0 i32) (param $n1 i32) (result i32) (i32.add (local.get 0) (i32.add (local.get 1) (i32.const 1))))
  (func $u2 (param $n0 i32) (param $n1 i32) (result i32) (i32.add (local.get 0) (i32.add (local.get 1) (i32.const 2))))

  (func (export "call_with_one_arg") (param $num i32) (param $func_ref i32) (result i32)
    (call_indirect (type $OneParameter) (local.get $num) (local.get $func_ref))
  )

  (func (export "call_with_two_args") (param $n1 i32) (param $n2 i32) (param $func_ref i32) (result i32)
    (call_indirect (type $TwoParameters) (local.get $n1) (local.get $n2) (local.get $func_ref))
  )

  (func (export "write_to_memory_index") (param $index i32) (param $value i32)
    (i32.store8 (local.get $index) (local.get $value))
  )
)