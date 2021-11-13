(module
  (memory (export "memory") 1)

  ;; 0 - 63
  ;; pixel data for drawing to canvas
  ;; initialize pixels as rgba(u8 u8 u8 u8) values
  (data $data (i32.const 0) 
    "\FF\00\00\FF"
    "\00\FF\00\FF"
    "\00\00\FF\FF"
    "\00\00\FF\FF"

    "\00\00\FF\FF"
    "\00\00\FF\FF"
    "\00\FF\00\FF"
    "\FF\00\00\FF"

    "\FF\00\00\FF"
    "\00\FF\00\FF"
    "\00\00\FF\FF"
    "\00\00\FF\FF"
    
    "\00\00\FF\FF"
    "\00\00\FF\FF"
    "\00\FF\00\FF"
    "\FF\00\00\FF"
  )

  ;; constants
  (func $HEIGHT (export "HEIGHT") (result i32) (i32.const 4))
  (func $WIDTH (export "WIDTH") (result i32) (i32.const 4))
  (func $BPP (export "BPP")(result i32) (i32.const 4)) ;; bytes per fixel
  (func $CANVAS_BUFFER_OFFSET (export "CANVAS_BUFFER_OFFSET") (result i32) (i32.const 0))
  (func $CANVAS_BUFFER_LENGTH (export "CANVAS_BUFFER_LENGTH") (result i32)
    call $WIDTH
    call $HEIGHT
    i32.mul
    call $BPP
    i32.mul
  )

  (func (export "get_num") (param $offset i32) (result i32)
    ;; offset is treated as a u8 integer
    ;; interprets bytes that it finds as a u8
    (i32.load8_u (local.get $offset))
  )

  (func (export "set_num") (param $offset i32) (param $value i32)
    ;; the offset is treated as a u8 offset, not i32
    ;; and any value over 255 is wrapped back down to 0
    (i32.store8 (local.get $offset) (local.get $value))
  )
)