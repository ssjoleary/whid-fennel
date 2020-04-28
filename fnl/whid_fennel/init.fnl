(module whid_fennel.init
  {require {nvim aniseed.nvim}})

(def win nil)
(def buf nil)
(def position 0)

(defn- centre
  [str]
  (let [width (nvim.win_get_width 0)
        shift (- (math.floor (/ width 2)) (math.floor (/ (string.len str) 2)))]
    (.. (string.rep " " shift) str)))

(defn open_window
  []
  (set buf (nvim.create_buf false true))
  (let [border_buf   (nvim.create_buf false true)
        _            (nvim.buf_set_option buf :bufhidden :wipe)
        __           (nvim.buf_set_option buf :filetype :whid_fennel)
        width        (nvim.get_option :columns)
        height       (nvim.get_option :lines)
        win_height   (math.ceil (- (* height 0.8) 4))
        win_width    (math.ceil (* width 0.8))
        row          (math.ceil (- (/ (- height win_height) 2) 1))
        col          (math.ceil (/ (- width win_width) 2))
        border_opts  {:style    :minimal
                      :relative :editor
                      :width    (+ win_width 2)
                      :height   (+ win_height 2)
                      :row      (- row 1)
                      :col      (- col 1)}
        opts         {:style    :minimal
                      :relative :editor
                      :width    win_width
                      :height   win_height
                      :row      row
                      :col      col}
        border_lines [(.. "╔" (string.rep "═" win_width) "╗")]
        middle_line  (.. "║" (string.rep " " win_width) "║")]

    (for [i 1 win_height]
      (table.insert border_lines middle_line))
    (table.insert border_lines (.. "╚" (string.rep "=" win_width) "╝"))
    (nvim.buf_set_lines border_buf 0 -1 false border_lines)

    (nvim.open_win border_buf true border_opts)
    (set win (nvim.open_win buf true opts))
    (nvim.command (.. "au BufWipeout <buffer> exe \"silent bwipeout!\" " border_buf))

    (nvim.win_set_option win "cursorline" true)

    (nvim.buf_set_lines buf 0 -1 false [ (centre "What have I done???") "" ""])
    (nvim.buf_add_highlight buf -1 "WhidHeader" 0 0 -1)))

(defn update_view
  [direction]
  (nvim.buf_set_option buf "modifiable" true)
  (set position (+ position direction))
  (if (< position 0)
    (set position 0))

  (let [result (nvim.call_function "systemlist"
                                   [(.. "git diff-tree --no-commit-id --name-only -r HEAD~" position)])
        result_table []]
    (if (= #result 0)
      (table.insert result ""))
    (each [index value (ipairs result)]
      (table.insert result_table index (.. "  " (. result index))))

    (nvim.buf_set_lines buf 1 2 false [(centre (.. "HEAD~" position))])
    (nvim.buf_set_lines buf 3 -1 false result_table)

    (nvim.buf_add_highlight buf -1 "whidSubHeader" 1 0 -1)
    (nvim.buf_set_option buf "modifiable" false)))

(defn close_window
  []
  (nvim.win_close win true))

(defn open_file
  []
  (let [str (nvim.get_current_line)]
    (close_window)
    (nvim.command (.. "edit " str))))

(defn move_cursor
  []
  (let [new_pos (-> (nvim.win_get_cursor win)
                    (. 1)
                    (- 1))]
    (nvim.win_set_cursor win {(math.max 4 new_pos) 0})))

(defn set_mappings
  [buf]
  (let [mappings    {"q"    "close_window()"
                     "<cr>" "open_file()"
                     "["    "update_view(-1)"
                     "]"    "update_view(1)"
                     "h"    "update_view(-1)"
                     "l"    "update_view(1)"
                     "k"    "move_cursor()"}
        other_chars ["a" "b" "c" "d" "e" "f" "g" "i" "n" "o" "p" "r" "s" "t" "u" "v" "w" "x" "y" "z"]]
    (each [k v (pairs mappings)]
      (nvim.buf_set_keymap buf "n" k (.. ":lua require\"whid_fennel\"." v "<cr>") {:nowait true :noremap true :silent true}))

    (each [index value (ipairs other_chars)]
      (nvim.buf_set_keymap buf "n" value "" {:nowait true :noremap true :silent true})
      (nvim.buf_set_keymap buf "n" (string.upper value) "" {:nowait true :noremap true :silent true})
      (nvim.buf_set_keymap buf "n" (.. "<c-" value ">") "" {:nowait true :noremap true :silent true}))))

(defn whid_fennel
  []
  (set position 0)
  (-> (open_window)
      (set_mappings))
  (update_view 0)
  (nvim.win_set_cursor win {4 0}))

{:whid_fennel  whid_fennel
 :update_view  update_view
 :open_file    open_file
 :move_cursor  move_cursor
 :close_window close_window}
