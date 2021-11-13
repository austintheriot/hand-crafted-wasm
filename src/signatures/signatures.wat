(module 
  ;; param types
  ;; for now, the only supported types are i32, i64, f32, and f64
  (func (param i32) (param i64) (param f32) (param f64))
  ;; more compact syntax:
  (func (param i32 i64 f32 f64))

  ;; numbered parameters
  (func (param i32) (param i32) (param i32) 
    local.get 0
    local.get 1
    local.get 2
  )

  ;; named parameters - these get compiled down to numbered params in .wasm
  (func (param $arg0 i32) (param $arg1 i32) (param $arg2 i32) 
    local.get $arg0
    local.get $arg1
    local.get $arg2
  )

  ;; return type
  (func (result i32) (
    i32.const 0
  ))

  ;; not specifying a result means no return value
  ;; if no function name is specified, then it is identifiable by its integer
  ;; this function takes no parameters and outputs no return value (but it is valid)
  (func)
)