(module
  ;; global values imported from JS
  (global $const_js_global (import "js" "const_js_global") i32) ;; const
  (global $mut_js_global (import "js" "mut_js_global") (mut i32)) ;; mut
  ;; globals values initialized in wasm
  (global $const_wasm_global i32 i32.const 1) ;; const
  (global $mut_wasm_global (mut i32) i32.const -100)  ;; mut


  ;; retrieve global values
  (func (export "get_const_js_global") (result i32) global.get $const_js_global)
  (func (export "get_mut_js_global") (result i32) global.get $mut_js_global)
  (func (export "get_const_wasm_global") (result i32) global.get $const_wasm_global)
  (func (export "get_mut_wasm_global") (result i32) global.get $mut_wasm_global)


  ;; modify global values
  (func (export "inc_mut_js_global") 
    global.get $mut_js_global
    i32.const 1
    i32.add
    global.set $mut_js_global
  )
  (func (export "inc_mut_wasm_global") 
    global.get $mut_wasm_global
    i32.const 1
    i32.add
    global.set $mut_wasm_global
  )
)