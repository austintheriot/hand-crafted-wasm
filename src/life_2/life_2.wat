;; CONWAY'S GAME OF LIFE
;; variation 1 - make alive if 2 or 4 neighbors
;; crates maze

(module
  ;; IMPORTS
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  (import "console" "log" (func $log (param i32)))
  (import "console" "log" (func $log_float (param f32)))
  (import "Math" "random" (func $random (result f64)))

  ;; MEMORY
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;; S = size of cell array
  ;; [0xS..4xS)  canvas data: u8s grouped in 4: rgba() style
  ;; [4xS..5xS)  original live/dead data cells: u8s
  ;; [5xS..6xS)  copy of live/dead cells for reference on next frame: u8s 

  (memory (export "memory") 9)
  
  ;; constant globals
  (global $WIDTH (export "WIDTH") i32 (i32.const 300))
  (global $HEIGHT (export "HEIGHT") i32 (i32.const 300))
  (global $NUM_CELLS (mut i32) (i32.const 0))

  ;; interaction state
  (global $MOUSE_X (mut f32) (f32.const 0))
  (global $MOUSE_Y (mut f32) (f32.const 0))
  (global $CANVAS_WIDTH (mut f32) (f32.const 0))
  (global $CANVAS_HEIGHT (mut f32) (f32.const 0))
  ;; 0 = mouse up, 1 = mouse down
  (global $MOUSE_STATE (mut i32) (i32.const 0))
  ;; 0 = pause, 1 = play
  (global $PLAY_STATE (mut i32) (i32.const 1))

  ;; canvas data
  (global $BPP (export "BPP") i32 (i32.const 4)) ;; bytes per pixel
  (global $CANVAS_MEMORY_OFFSET (export "CANVAS_MEMORY_OFFSET") i32 (i32.const 0))
  (global $CANVAS_MEMORY_LENGTH (export "CANVAS_MEMORY_LENGTH") (mut i32) (i32.const 0))
  
  ;; cell data
  (global $CELL_MEMORY_OFFSET (mut i32) (i32.const 0))
  (global $CELL_MEMORY_LENGTH (mut i32) (i32.const 0))
  (global $CELL_MEMORY_OFFSET_COPY (mut i32) (i32.const 0))
  (global $CHANCE_OF_SPAWNING f64 (f64.const 0.1))
  (global $FADE_DECREMENT i32 (i32.const 1))
  (global $ALIVE i32 (i32.const 255))
  (global $DEAD i32 (i32.const 0))

  ;; callback enum (in lieu of a table)
  (global $DRAW_CELL i32 (i32.const 0))
  (global $SPAWN_RANDOM i32 (i32.const 1))
  (global $COPY_CELL i32 (i32.const 2))
  (global $UPDATE_CELL i32 (i32.const 3))

  ;; INIT GLOBALS 
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  (func $set_num_cells
    global.get $HEIGHT
    global.get $WIDTH
    i32.mul
    global.set $NUM_CELLS
  )
  (func $set_cell_memory_length
    global.get $WIDTH
    global.get $HEIGHT
    i32.mul
    global.set $CELL_MEMORY_LENGTH
  )
  (func $set_canvas_memory_length
    global.get $CELL_MEMORY_LENGTH
    global.get $BPP
    i32.mul
    global.set $CANVAS_MEMORY_LENGTH
  )
  (func $set_cell_memory_offset
    global.get $CANVAS_MEMORY_OFFSET
    global.get $CANVAS_MEMORY_LENGTH
    i32.add
    global.set $CELL_MEMORY_OFFSET
  )
  (func $set_cell_memory_offset_copy
    global.get $CELL_MEMORY_OFFSET
    global.get $CELL_MEMORY_LENGTH
    i32.add
    global.set $CELL_MEMORY_OFFSET_COPY
  )

  ;; CANVAS LISTENERS
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   (func (export "set_mouse_state") (param $mouse_state i32)
    (global.set $MOUSE_STATE (local.get $mouse_state))   

    ;; if mouse is now down, mark cell alive wherever it is
    (if (i32.eq (global.get $MOUSE_STATE) (i32.const 1))
      (then 
        (call $mark_cell_alive_from_input)
      )
    )

    ;; if play state is paused, update canvas manually
    (if (i32.eqz (global.get $PLAY_STATE)) (call $iterate_through_cells (global.get $DRAW_CELL)))
  )

  (func (export "set_play_state") (param $play_state i32)
    (global.set $PLAY_STATE (local.get $play_state))   
  )

  (func (export "set_mouse_position") (param $x f32)  (param $y f32) (param $width f32) (param $height f32)
    (global.set $MOUSE_X (local.get $x))   
    (global.set $MOUSE_Y (local.get $y))   
    (global.set $CANVAS_WIDTH (local.get $width))   
    (global.set $CANVAS_HEIGHT (local.get $height))   

    ;; if mouse sate is down, mark cell alive
    (if (i32.eq (global.get $MOUSE_STATE) (i32.const 1))
      (then (call $mark_cell_alive_from_input))
    )

    ;; if play state is paused, update canvas manually
    (if (i32.eqz (global.get $PLAY_STATE)) (call $iterate_through_cells (global.get $DRAW_CELL)))
  )

  ;; FUNCTIONS
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  
  ;; get max between two i32 values
  (func $i32_max (param i32 i32) (result i32)
    (select
      (local.get 0)
      (local.get 1)
      (i32.gt_s (local.get 0) (local.get 1))
    )
  )

  ;; get min between two i32 values
  (func $i32_min (param i32 i32) (result i32)
    (select
      (local.get 0)
      (local.get 1)
      (i32.lt_s (local.get 0) (local.get 1))
    )
  )

  ;; clamp an i32 number between two other values 
  (func $i32_clamp (param $min i32) (param $num i32) (param $max i32) (result i32)
    (call $i32_min 
      (call $i32_max 
        (local.get $num) 
        (local.get $min)
      ) 
      (local.get $max)
    )
  )

  (func $get_cell_num_from_coords (param $x i32) (param $y i32) (result i32)
    ;; cell number = (y * width) + x
    global.get $WIDTH
    local.get $y
    i32.mul
    local.get $x
    i32.add
  )

  (func $mark_cell_alive_from_input
    (local $x_coord i32)
    (local $y_coord i32)
    (local $cell_number i32)
    (local $cell_mem_index i32)
    (local $cell_copy_mem_index i32)
    (local.set $x_coord (i32.load (i32.const 0)))
    (local.set $y_coord (i32.load (i32.const 1)))

    ;; calculate cell position where mouse is on canvas
    (local.set $x_coord 
      (call $i32_clamp 
        ;; don't go below 0
        (i32.const 0)
        ;; calculate cell coordinate
        (i32.trunc_sat_f32_u
          (f32.floor
            (f32.mul
              (f32.div 
                (global.get $MOUSE_X) 
                (global.get $CANVAS_WIDTH)
              ) 
              (f32.convert_i32_s (global.get $WIDTH))
            )
          )
        )
        ;; don't go above width - 1
        (i32.sub (global.get $WIDTH) (i32.const 1))
      )
    )
    (local.set $y_coord 
      (call $i32_clamp 
        ;; don't go below 0
        (i32.const 0)
        ;; calculate cell coordinate
        (i32.trunc_sat_f32_u
          (f32.floor
            (f32.mul
              (f32.div 
                (global.get $MOUSE_Y) 
                (global.get $CANVAS_HEIGHT)
              ) 
              (f32.convert_i32_s (global.get $HEIGHT))
            )
          )
        )
        ;; don't go above height - 1
        (i32.sub (global.get $HEIGHT) (i32.const 1))
      )
    )
  
    (local.set $cell_number (call $get_cell_num_from_coords (local.get $x_coord) (local.get $y_coord)))
    (local.set $cell_mem_index (call $cell_number_to_cell_mem_index (local.get $cell_number)))
    (local.set $cell_copy_mem_index (call $cell_number_to_cell_copy_mem_index (local.get $cell_number)))

    (i32.store8 (local.get $cell_mem_index) (global.get $ALIVE))
    (i32.store8 (local.get $cell_copy_mem_index) (global.get $ALIVE))
  )

  ;; 255 == alive
  ;; anything less than 255 === dead
  (func $is_cell_at_actual_i_alive (param $actual_i i32) (result i32)
    (i32.load8_u (local.get $actual_i))
    (global.get $ALIVE)
    i32.eq
  )

   (func $is_copy_cell_alive (param $actual_i i32) (result i32)
    (if 
      ;; too far left:
      (i32.or (i32.lt_s 
        (local.get $actual_i) 
        (global.get $CELL_MEMORY_OFFSET_COPY)
      )
      ;; too far right
      (i32.gt_s 
        (local.get $actual_i) 
        (i32.add 
          (global.get $CELL_MEMORY_OFFSET_COPY) 
          (global.get $CELL_MEMORY_LENGTH)
        )
      )
    )
      (return (global.get $DEAD))
    )

    ;; else return the actual value of the cell
    (i32.load8_u (local.get $actual_i))
    (global.get $ALIVE)
    i32.eq
  )

  ;; converts cell number to memory index of cell
  (func $cell_number_to_cell_mem_index (param $cell_number i32) (result i32)
    (i32.add 
      (local.get $cell_number)
      (global.get $CELL_MEMORY_OFFSET)
    )
  )

  ;; converts cell number to memory index of copied cell
  (func $cell_number_to_cell_copy_mem_index (param $cell_number i32) (result i32)
    (i32.add 
      (local.get $cell_number)
      (global.get $CELL_MEMORY_OFFSET_COPY)
    )
  )

  ;; converts cell number to memory index of canvas cell pixel
  (func $cell_number_to_pixel_mem_index (param $cell_number i32) (result i32)
    (i32.add 
      (i32.mul
        (local.get $cell_number)
        (global.get $BPP)
      )
      (global.get $CANVAS_MEMORY_OFFSET)
    )
  )

  ;; convert cell data into drawable pixels for the canvas
  (func $draw_cell (param $raw_i i32)
    (local $cell_i i32)
    (local $pixel_i i32)
    (local $cell_value i32)
    (local $r i32)
    (local $g i32)
    (local $b i32)

    ;; convert raw i to cell i & pixel i
    (local.set $cell_i (call $cell_number_to_cell_mem_index (local.get $raw_i)))
    (local.set $pixel_i (call $cell_number_to_pixel_mem_index (local.get $raw_i)))
    (local.set $cell_value (i32.load8_u (local.get $cell_i)))

    (block $block
      ;; alive (255)
      (if (i32.eq (local.get $cell_value) (global.get $ALIVE))
        (then
          (local.set $r (local.get $cell_value))
          (local.set $g (local.get $cell_value))
          (local.set $b (local.get $cell_value))
          (br $block)
        )
      )

      ;; fuschia
      (if (i32.gt_u (local.get $cell_value) (i32.const 250))
        (then
          (local.set $r (i32.div_u (i32.mul (local.get $cell_value) (i32.const 4)) (i32.const 5)))
          (local.set $g (i32.const 0))
          (local.set $b (i32.div_u (i32.mul (local.get $cell_value) (i32.const 4)) (i32.const 5)))
          (br $block)
        )
      )

      ;; teal
      (if (i32.gt_u (local.get $cell_value) (i32.const 240))
        (then
          (local.set $r (i32.div_u (i32.mul (local.get $cell_value) (i32.const 1)) (i32.const 4)))
          (local.set $g (i32.div_u (i32.mul (local.get $cell_value) (i32.const 2)) (i32.const 5)))
          (local.set $b (i32.div_u (i32.mul (local.get $cell_value) (i32.const 2)) (i32.const 5)))
          (br $block)
        )
      )

      ;; muted teal
      (if (i32.gt_u (local.get $cell_value) (i32.const 220))
        (then
          (local.set $r (i32.div_u (local.get $cell_value) (i32.const 5)))
          (local.set $g (i32.div_u (local.get $cell_value) (i32.const 4)))
          (local.set $b (i32.div_u (local.get $cell_value) (i32.const 3)))
          (br $block)
        )
      )

      ;; blue
      (if (i32.gt_u (local.get $cell_value) (i32.const 190))
        (then
          (local.set $r (i32.div_u (local.get $cell_value) (i32.const 6)))
          (local.set $g (i32.div_u (local.get $cell_value) (i32.const 6)))
          (local.set $b (i32.div_u (local.get $cell_value) (i32.const 3)))
          (br $block)
        )
      )

      ;; dark blue
      (if (i32.gt_u (local.get $cell_value) (i32.const 85))
        (then
          (local.set $r (i32.div_u (local.get $cell_value) (i32.const 6)))
          (local.set $g (i32.div_u (local.get $cell_value) (i32.const 6)))
          (local.set $b (i32.div_u (local.get $cell_value) (i32.const 4)))
          (br $block)
        )
      )

      ;; gray
      (local.set $r (i32.div_u (local.get $cell_value) (i32.const 6)))
      (local.set $g (i32.div_u (local.get $cell_value) (i32.const 6)))
      (local.set $b (i32.div_u (local.get $cell_value) (i32.const 6)))
    )

    ;; update canvas pixel data
    (i32.store8 (local.get $pixel_i) (local.get $r))
    (i32.store8 (i32.add (local.get $pixel_i) (i32.const 1)) (local.get $g))
    (i32.store8 (i32.add (local.get $pixel_i) (i32.const 2)) (local.get $b))
    (i32.store8 (i32.add (local.get $pixel_i) (i32.const 3)) (i32.const 0xFF))
  )

  ;; randomly mark cell as alive or dead
  (func $spawn_random (param $raw_i i32)
    (local $cell_i i32)
    (local.set $cell_i (call $cell_number_to_cell_mem_index (local.get $raw_i)))

    ;; mark cell alive or dead
    (if (f64.lt 
          (call $random)
          (global.get $CHANCE_OF_SPAWNING)
        )
        (then (i32.store8 (local.get $cell_i) (global.get $ALIVE)))
        (else (i32.store8 (local.get $cell_i) (global.get $DEAD)))
      )
    )

    (func $get_num_live_neighbors (param $actual_i i32) (result i32)
    (local $num_live_neighbors i32)
    (local.set $num_live_neighbors (i32.const 0))

    ;; top left
    (if 
      (call $is_copy_cell_alive 
        (i32.sub 
          (i32.sub 
            (local.get $actual_i)
            (global.get $WIDTH)
          )
          (i32.const 1)
        )
      )
       (local.set $num_live_neighbors (i32.add (local.get $num_live_neighbors) (i32.const 1)))
    )

    ;; top
    (if 
      (call $is_copy_cell_alive 
        (i32.sub 
            (local.get $actual_i)
            (global.get $WIDTH)
        )
      )
      (local.set $num_live_neighbors (i32.add (local.get $num_live_neighbors) (i32.const 1)))
    )

    ;; top right
    (if 
      (call $is_copy_cell_alive 
        (i32.add 
          (i32.sub 
            (local.get $actual_i)
            (global.get $WIDTH)
          )
          (i32.const 1)
        )
      )
        (local.set $num_live_neighbors (i32.add (local.get $num_live_neighbors) (i32.const 1)))
    )

    ;; left
    (if 
      (call $is_copy_cell_alive 
        (i32.sub 
            (local.get $actual_i)
            (i32.const 1)
        )
      )
      (local.set $num_live_neighbors (i32.add (local.get $num_live_neighbors) (i32.const 1)))
    )

    ;; right
     (if 
      (call $is_copy_cell_alive 
        (i32.add 
            (local.get $actual_i)
            (i32.const 1)
        )
      )
      (local.set $num_live_neighbors (i32.add (local.get $num_live_neighbors) (i32.const 1)))
    )

    ;; bottom left
    (if 
      (call $is_copy_cell_alive 
        (i32.sub 
          (i32.add 
            (local.get $actual_i)
            (global.get $WIDTH)
          )
          (i32.const 1)
        )
      )
       (local.set $num_live_neighbors (i32.add (local.get $num_live_neighbors) (i32.const 1)))
    )

    ;; bottom 
    (if 
      (call $is_copy_cell_alive 
        (i32.add 
          (local.get $actual_i)
          (global.get $WIDTH)
        )
      )
       (local.set $num_live_neighbors (i32.add (local.get $num_live_neighbors) (i32.const 1)))
    )

    ;; bottom right
    (if 
      (call $is_copy_cell_alive 
        (i32.add 
          (i32.add 
            (local.get $actual_i)
            (global.get $WIDTH)
          )
          (i32.const 1)
        )
      )
       (local.set $num_live_neighbors (i32.add (local.get $num_live_neighbors) (i32.const 1)))
    )


    local.get $num_live_neighbors
  )

  (; The rules of Conway's Game of Life:
  1. Any live cell with two or three live neighbours survives.
  2. Any dead cell with three live neighbours becomes a live cell.
  3. All other live cells die in the next generation. Similarly, all other dead cells stay dead. ;)
  (func $update_cell (param $raw_i i32)
    (local $cell_i i32)
    (local $cell_copy_i i32)
    (local $num_live_neighbors i32)
    (local $current_cell_is_alive i32)
    (local $next_life_state i32)
    (local $cell_value i32)
    (local $decremented_cell_value i32)

    ;; convert raw i to cell i & cell copy i
    (local.set $cell_i (call $cell_number_to_cell_mem_index (local.get $raw_i)))
    (local.set $cell_copy_i (call $cell_number_to_cell_copy_mem_index (local.get $raw_i)))

    ;; get current state of cell
    (local.set $num_live_neighbors (call $get_num_live_neighbors (local.get $cell_copy_i)))
    (local.set $current_cell_is_alive (call $is_cell_at_actual_i_alive (local.get $cell_copy_i)))
    (local.set $cell_value (i32.load8_u (local.get $cell_copy_i)))
    (local.set $decremented_cell_value (i32.sub (local.get $cell_value) (global.get $FADE_DECREMENT)))

    ;; decrement cell value
    (if (i32.gt_s (local.get $decremented_cell_value) (global.get $DEAD))
      (then (local.set $cell_value (local.get $decremented_cell_value)))
      (else (local.set $cell_value (global.get $DEAD)))
    )

    (if (i32.or 
          ;; alive and 2 or 3 neighbors
          (i32.and 
            (local.get $current_cell_is_alive)
            (i32.or 
              (i32.eq 
                (local.get $num_live_neighbors)
                (i32.const 2)
              )
              (i32.eq 
                (local.get $num_live_neighbors)
                (i32.const 4)
              )
            ) 
          )
          ;; dead with 3 neighbors
          (i32.eq 
            (local.get $num_live_neighbors)
            (i32.const 3)
          )
        )
        ;; Any live cell with two or three live neighbours survives.
        ;; Any dead cell with three live neighbours becomes a live cell.
        (then (local.set $next_life_state (global.get $ALIVE)))

        ;; All other live cells die in the next generation. 
        ;; All other dead cells stay dead. 
        (else (local.set $next_life_state (local.get $cell_value)))
    )

    ;; set life state of the current actual cell
    (i32.store8 (local.get $cell_i) (local.get $next_life_state))
  )

  (func $copy_cell (param $raw_i i32)
    (local $cell_i i32)
    (local $cell_copy_i i32)

    ;; convert raw i to cell i & cell copy i
    (local.set $cell_i (call $cell_number_to_cell_mem_index (local.get $raw_i)))
    (local.set $cell_copy_i (call $cell_number_to_cell_copy_mem_index (local.get $raw_i)))

    (i32.store8 (local.get $cell_copy_i) (i32.load8_u (local.get $cell_i)))
  )

  (func $iterate_through_cells (param $cb_i i32)
    (local $i i32)
    (local.set $i (i32.const 0))

    (loop $loop

      ;; perform indicated callback
      (if (i32.eq (local.get $cb_i) (global.get $SPAWN_RANDOM))
        (call $spawn_random (local.get $i))
      )
      (if (i32.eq (local.get $cb_i) (global.get $DRAW_CELL))
        (call $draw_cell (local.get $i))
      )
      (if (i32.eq (local.get $cb_i) (global.get $UPDATE_CELL))
        (call $update_cell (local.get $i))
      )
      (if (i32.eq (local.get $cb_i) (global.get $COPY_CELL))
        (call $copy_cell (local.get $i))
      )

      ;; loop until reaching the end of cells
      (if (i32.eq (local.get $i) (i32.sub (global.get $NUM_CELLS)) (i32.const 1))
        (then return)
        (else 
          (local.set $i (i32.add (local.get $i) (i32.const 1)))
          br $loop
        )
      )
    )
  )

  ;; prepares game state
  (func $init (export "init")
    ;; init globals
    (call $set_num_cells)
    (call $set_cell_memory_length)
    (call $set_canvas_memory_length)
    (call $set_cell_memory_offset)
    (call $set_cell_memory_offset_copy)

    ;; init cell & canvas state
    (call $iterate_through_cells (global.get $SPAWN_RANDOM))
    (call $iterate_through_cells (global.get $COPY_CELL))
    (call $iterate_through_cells (global.get $DRAW_CELL))
  )

  ;; update game state on every tick
  (func $update (export "update")
    (if (i32.eqz (global.get $PLAY_STATE)) (return))
    (call $iterate_through_cells (global.get $UPDATE_CELL))
    (call $iterate_through_cells (global.get $COPY_CELL))
    (call $iterate_through_cells (global.get $DRAW_CELL))
  )
)