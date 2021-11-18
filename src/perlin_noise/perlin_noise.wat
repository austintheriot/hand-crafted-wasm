;; This is a direct WebAssembly port of processing/p5's noise() function.
;; For more information on the details of their implementation, see:
;; https://github.com/processing/p5.js/blob/374acfb44588bfd565c54d61264df197d798d121/src/math/noise.js

(module
  ;; IMPORTS
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  (import "Math" "random" (func $random (result f64)))
  (import "Math" "cos" (func $cos (param f64) (result f64)))
  (global $PI (import "Math" "PI") f64)
  (import "console" "log" (func $log (param i32)))
  (import "console" "log" (func $log_float (param f64)))

  ;; MEMORY
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  (memory (export "memory") 1)

  (global $PERLIN_YWRAPB i32 (i32.const 4))
  (global $PERLIN_YWRAP i32 (i32.const 16))
  (global $PERLIN_ZWRAPB i32 (i32.const 8))
  (global $PERLIN_ZWRAP i32 (i32.const 256))
  (global $PERLIN_SIZE i32 (i32.const 4095))
  (global $FLOAT_BYTES i32 (i32.const 8))

  (global $PERLIN_OCTAVES (mut i32) (i32.const 4))
  (global $PERLIN_AMP_FALLOFF (mut f64) (f64.const 0.5))

  (func $scaled_cosine (param $i f64) (result f64)
    (f64.mul
      (f64.const 0.5)
      (f64.sub 
        (f64.const 1)
        (call $cos
          (f64.mul
            (local.get $i)
            (global.get $PI)
          )
        )
      )
    )
  )

  (func $init_array 
    (local $i i32)
      (loop $loop
        (if (i32.lt_s
            (local.get $i) 
            (i32.mul 
              (i32.add 
                (global.get $PERLIN_SIZE) 
                (i32.const 1)
              ) 
              (global.get $FLOAT_BYTES)
            )
          )
          (then
            (f64.store (local.get $i) (call $random))
            (local.set $i (i32.add (local.get $i) (i32.const 8)))
            (br $loop)
          )
        )
      )
  )
  
  (func (export "perlin_noise") (param $x f64) (param $y f64) (param $z f64) (result f64)
    (local $xi i32)
    (local $yi i32)
    (local $zi i32)
    (local $xf f64)
    (local $yf f64)
    (local $zf f64)
    (local $rxf f64)
    (local $ryf f64)
    (local $r f64)
    (local $ampl f64)
    (local $n1 f64)
    (local $n2 f64)
    (local $n3 f64)
    (local $o i32)
    (local $of i32)
    
    ;; check if array is empty
    (if (i64.eqz (i64.load (i32.const 0)))
      (then (call $init_array))
    )

    ;; make sure input is positive
    (local.set $x (f64.abs (local.get $x)))
    (local.set $y (f64.abs (local.get $y)))
    (local.set $z (f64.abs (local.get $z)))

    (local.set $xi (i32.trunc_sat_f64_u (local.get $x)))
    (local.set $yi (i32.trunc_sat_f64_u (local.get $y)))
    (local.set $zi (i32.trunc_sat_f64_u (local.get $z)))

    (local.set $xf
      (f64.sub
        (local.get $x)
        (f64.convert_i32_s (local.get $xi))
      )
    )
    (local.set $yf
      (f64.sub
        (local.get $y)
        (f64.convert_i32_s (local.get $yi))
      )
    )
    (local.set $zf
      (f64.sub
        (local.get $z)
        (f64.convert_i32_s (local.get $zi))
      )
    )

    (local.set $r (f64.const 0))
    (local.set $ampl (f64.const 0.5))
    (local.set $o (i32.const 0))


    (loop $loop
      (if (i32.lt_s (local.get $o) (global.get $PERLIN_OCTAVES))
        (then
          (local.set $of
            (i32.add
              (i32.add
                (local.get $xi)
                (i32.shl
                  (local.get $yi)
                  (global.get $PERLIN_YWRAPB)
                )
              )
              (i32.shl
                (local.get $zi)
                (global.get $PERLIN_ZWRAPB)
              )
            )
          )


          (local.set $rxf (call $scaled_cosine (local.get $xf)))
          (local.set $ryf (call $scaled_cosine (local.get $yf)))


          (local.set $n1
            (f64.load
              (i32.mul
                (i32.and
                  (local.get $of)
                  (global.get $PERLIN_SIZE)
                )
                (global.get $FLOAT_BYTES)
              )
            )
          )

          (local.set $n1
            (f64.add
              (local.get $n1)
              (f64.mul
                (local.get $rxf)
                (f64.sub
                  (f64.load
                    (i32.mul
                      (i32.and
                        (i32.add
                          (local.get $of)
                          (i32.const 1)
                        )
                        (global.get $PERLIN_SIZE)
                      )
                      (global.get $FLOAT_BYTES)
                    )
                  )
                  (local.get $n1)
                )
              )
            )
          )

          (local.set $n2
            (f64.load
              (i32.mul
                (i32.and
                  (i32.add
                    (local.get $of)
                    (global.get $PERLIN_YWRAP)
                  )
                  (global.get $PERLIN_SIZE)
                )
                (global.get $FLOAT_BYTES)
              )
            )
          )

          (local.set $n2
            (f64.add
              (local.get $n2)
              (f64.mul
                (local.get $rxf)
                (f64.sub
                  (f64.load
                    (i32.mul
                      (i32.and
                        (i32.add
                          (i32.add 
                            (local.get $of)
                            (global.get $PERLIN_YWRAP)
                          )
                          (i32.const 1)
                        )
                        (global.get $PERLIN_SIZE)
                      )
                      (global.get $FLOAT_BYTES)
                    )
                  )
                  (local.get $n2)
                )
              )
            )
          )

          (local.set $n1
            (f64.add
              (local.get $n1)
              (f64.mul
                (local.get $ryf)
                (f64.sub
                  (local.get $n2)
                  (local.get $n1)
                )
              )
            )
          )




          (local.set $of
            (i32.add
              (local.get $of)
              (global.get $PERLIN_ZWRAP)
            )
          )




          (local.set $n2
            (f64.load
              (i32.mul
                (i32.and
                  (local.get $of)
                  (global.get $PERLIN_SIZE)
                )
                (global.get $FLOAT_BYTES)
              )
            )
          )

          (local.set $n2
            (f64.add
              (local.get $n2)
              (f64.mul
                (local.get $rxf)
                (f64.sub
                  (f64.load
                    (i32.mul
                      (i32.and
                        (i32.add
                          (local.get $of)
                          (i32.const 1)
                        )
                        (global.get $PERLIN_SIZE)
                      )
                      (global.get $FLOAT_BYTES)
                    )
                  )
                  (local.get $n2)
                )
              )
            )
          )

          (local.set $n3
            (f64.load
              (i32.mul
                (i32.and
                  (i32.add
                    (local.get $of)
                    (global.get $PERLIN_YWRAP)
                  )
                  (global.get $PERLIN_SIZE)
                )
                (global.get $FLOAT_BYTES)
              )
            )
          )
          
          (local.set $n3
            (f64.add
              (local.get $n3)
              (f64.mul
                (local.get $rxf)
                (f64.sub
                  (f64.load
                    (i32.mul
                      (i32.and
                        (i32.add
                          (i32.add 
                            (local.get $of)
                            (global.get $PERLIN_YWRAP)
                          )
                          (i32.const 1)
                        )
                        (global.get $PERLIN_SIZE)
                      )
                      (global.get $FLOAT_BYTES)
                    )
                  )
                  (local.get $n3)
                )
              )
            )
          )

          (local.set $n2
            (f64.add
              (local.get $n2)
              (f64.mul
                (local.get $ryf)
                (f64.sub
                  (local.get $n3)
                  (local.get $n2)
                )
              )
            )
          )

          (local.set $n1
            (f64.add
              (local.get $n1)
              (f64.mul
                (call $scaled_cosine (local.get $zf))
                (f64.sub
                  (local.get $n2)
                  (local.get $n1)
                )
              )
            )
          )


          (local.set $r
            (f64.add
              (local.get $r)
              (f64.mul
                (local.get $n1)
                (local.get $ampl)
              )
            )
          )

          (local.set $ampl
            (f64.mul
              (local.get $ampl)
              (global.get $PERLIN_AMP_FALLOFF)
            )
          )

          (local.set $xi
            (i32.shl
              (local.get $xi)
              (i32.const 1)
            )
          )

          (local.set $xf
            (f64.mul
              (local.get $xf)
              (f64.const 2)
            )
          )

          (local.set $yi
            (i32.shl
              (local.get $yi)
              (i32.const 1)
            )
          )

          (local.set $yf
            (f64.mul
              (local.get $yf)
              (f64.const 2)
            )
          )

          (local.set $zi
            (i32.shl
              (local.get $zi)
              (i32.const 1)
            )
          )

          (local.set $zf
            (f64.mul
              (local.get $zf)
              (f64.const 2)
            )
          )

          (if (f64.ge
              (local.get $xf)
              (f64.const 1)
            )
            (then
              (local.set $xi
                (i32.add
                  (local.get $xi)
                  (i32.const 1)
                )
              )
              (local.set $xf
                (f64.sub
                  (local.get $xf)
                  (f64.const 1)
                )
              )
            )
          )

          (if (f64.ge
              (local.get $yf)
              (f64.const 1)
            )
            (then
              (local.set $yi
                (i32.add
                  (local.get $yi)
                  (i32.const 1)
                )
              )
              (local.set $yf
                (f64.sub
                  (local.get $yf)
                  (f64.const 1)
                )
              )
            )
          )

          (if (f64.ge
              (local.get $zf)
              (f64.const 1)
            )
            (then
              (local.set $zi
                (i32.add
                  (local.get $zi)
                  (i32.const 1)
                )
              )
              (local.set $zf
                (f64.sub
                  (local.get $zf)
                  (f64.const 1)
                )
              )
            )
          )

          (local.set $o
            (i32.add
              (local.get $o)
              (i32.const 1)
            )
          )

          (br $loop)
        )
      )
    )

   (return (local.get $r))
  )
)