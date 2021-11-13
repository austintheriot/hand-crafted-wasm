(module
  (memory (export "memory") 1)

  (data $data (i32.const 0) 
    ;; 0-12
    "Hello, world!" ;; "string" style data is parsed into linear memory as UTF-8 binary characters

    ;; 13-25
    "\48\65\6C\6C\6F\2C\20\77\6F\72\6C\64\21" ;; data can also be stored in linear memory as raw hex values
  )

  ;; data can be specified in multiple blocks
  (data $data_2 (i32.const 26) 
   "?"
  )

  ;; (table (export "tbl") anyfunc (elem $thirteen $fourtytwo))
  ;; (func $thirteen (result i32) (i32.const 13))
  ;; (func $fourtytwo (result i32) (i32.const 42))
)