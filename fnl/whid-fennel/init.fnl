(module my-plugin.init
  {require {nvim aniseed.nvim}})

(def win nil)
(def buf nil)
(def position 0)

(defn- centre
  [str]
  (let [width (nvim.win_get_width 0)
        shift (- (math.floor (/ width 2)) (math.floor (/ (string.len str) 2)))]
    (.. (string.rep " " shift) str)))

(defn open-window
  []
  (set buf (nvim.create_buf false true))
  (let [border-buf   (nvim.create_buf false true)
        _            (nvim.buf_set_option buf :bufhidden :wipe)
        __           (nvim.buf_set_option buf :filetype :whid)
        width        (nvim.get_option :columns)
        height       (nvim.get_option :lines)
        win_height   (math.ceil (- (* height 0.8) 4))
        win_width    (math.ceil (* width 0.8))
        row          (math.ceil (- (/ (- height win_height) 2) 1))
        col          (math.ceil (/ (- width win_width) 2))
        border-opts  {:style    :minimal
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
        border-lines [(.. "╔" (string.rep "═" win_width) "╗")]
        middle-line  (.. "║" (string.rep " " win_width) "║")]

    (for [i 1 win_height]
      (table.insert border-lines middle-line))
    (table.insert border-lines (.. "╚" (string.rep "=" win_width) "╝"))
    (nvim.buf_set_lines border-buf 0 -1 false border-lines)

    (nvim.open_win border-buf true border-opts)
    (set win (nvim.open_win buf true opts))
    (nvim.command (.. "au BufWipeout <buffer> exe \"silent bwipeout!\" " border-buf))

    (nvim.win_set_option win "cursorline" true)

    (nvim.buf_set_lines buf 0 -1 false [ (centre "What have I done???") "" ""])
    (nvim.buf_add_highlight buf -1 "WhidHeader" 0 0 -1)))

(defn close_window
  []
  (nvim.win_close win true))

(defn set-mappings
  [buf]
  (let [mappings {:q "close_window()"}]
    (each [k v (pairs mappings)]
      (nvim.buf_set_keymap buf "n" k (.. ":lua require(" "whid." v ")<cr>") {:nowait true :noremap true :silent true}))))

(defn whid
  []
  (-> (open-window)
      (set-mappings)))
