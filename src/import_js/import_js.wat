(module
  ;; import JavaScript function 
  ;; enables logging from within WebAssembly
  (import "console" "log" (func $log_js (param i32) (param i32) (param i32) (param i32)))
  (import "math" "add" (func $add_js (param i32) (param i32) (result i32)))

  ;; stack values get consumed as function arguemnts in the same order
  ;; that they are added to the stack
  ;; i.e. $log, when called below, consumes the args as log(0, 1, 2, 3)
  (func (export "test_stack_order") (param i32) (param i32) (param i32) (param i32)
    local.get 0
    local.get 1
    local.get 2
    local.get 3
    call $log_js
  )

  ;; this function does the reverse of what you'd expect from wasm modules!
  ;; it imports JS functionality and runs it in WASM rather than the other way around!
  (func (export "add_and_log") (param $n1 i32) (param $n2 i32) 
    ;; add params together in various combinations to get 4 params total
    local.get $n1
    local.get $n1
    call $add_js

    local.get $n1
    local.get $n2
    call $add_js

    local.get $n2
    local.get $n1
    call $add_js

    local.get $n2
    local.get $n2
    call $add_js

    ;; log 4 combinations of parameter additions
    call $log_js
  )

  ;; re-export imported js function as a wasm function
  (export "log" (func $log_js))


  ;; run this function immediately when module is instantiated
  (func $prepared_log (call $log_js (i32.const 99) (i32.const 99) (i32.const 99) (i32.const 99)))
  (start $prepared_log)
)