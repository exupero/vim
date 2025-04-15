(module util
  {require {a aniseed.core
            str aniseed.string
            ts treesitter}})

(defn ifilter [pred iter]
  (let [result []]
    (each [i iter]
      (if (pred i)
        (table.insert result i)))
    result))

(defn split-lines [s]
  (str.split s "\n"))

(defn get-lines [start-row end-row]
  (vim.api.nvim_buf_get_lines 0 start-row end-row true))

(defn get-all-lines []
  (let [lines (vim.api.nvim_buf_get_lines 0 0 (vim.api.nvim_buf_line_count 0) false)]
    (table.concat lines "\n")))

(defn get-current-line []
  (vim.api.nvim_get_current_line))

(defn set-lines! [start-row end-row lines]
  (vim.api.nvim_buf_set_lines 0 start-row end-row true lines))

(defn get-cursor []
  (vim.api.nvim_win_get_cursor 0))

(defn set-cursor! [row col]
  (vim.api.nvim_win_set_cursor 0 [row col]))

(defn update-line! [f]
  (let [[row] (vim.api.nvim_win_get_cursor 0)
        [line] (get-lines (a.dec row) row)
        (replacement) (f line)]
    (set-lines! (a.dec row) row [replacement])))

(defn update-all-lines! [f]
  (let [lines (get-lines 0 -1)]
    (each [i line (ipairs lines)]
      (tset lines i (or (f line) line)))
    (set-lines! 0 -1 lines)))

(defn insert-mode! []
  (vim.cmd "startinsert"))

(defn repeatable [nm cmd]
   (vim.keymap.set :n (.. "<Plug>(" nm ")") (.. cmd ":silent! call repeat#set(\"\\<Plug>(" nm ")\")<CR>")))

(defn update-file-and-move-cursor! [f]
  (let [line-count (vim.api.nvim_buf_line_count 0)
        [row col] (vim.api.nvim_win_get_cursor 0)]
    (f)
    (let [new-line-count (vim.api.nvim_buf_line_count 0)
          diff (- new-line-count line-count)]
      (vim.api.nvim_win_set_cursor 0 [(+ row diff) col]))))

(defn insert-lines-at! [[row col] lines]
  (set-lines! row row lines))

(defn insert-lines! [lines]
  (insert-lines-at! (get-cursor) lines))

(defn insert-line-at-location! [[row] line]
  (let [[current-line] (get-lines (a.dec row) row)]
    (insert-lines-at!
      [(a.dec row) 0]
      [(.. (string.match current-line "(%s+)") line)])))

(defn insert-line-before-cursor! [line]
  (insert-line-at-location! (vim.api.nvim_win_get_cursor 0) line))

(defn insert-line-after-cursor! [line]
  (let [[row] (vim.api.nvim_win_get_cursor 0)]
    (insert-line-at-location! [(a.inc row)] line)))

(defn insert-line-before-mark! [mark line]
  (insert-line-at-location! (vim.api.nvim_buf_get_mark 0 mark) line))

; https://neovim.discourse.group/t/function-that-return-visually-selected-text/1601
(defn visual-selection []
  (let [s-start (vim.fn.getpos "'<")
        s-end (vim.fn.getpos "'>")
        n-lines (+ (math.abs (- (. s-end 2) (. s-start 2))) 1)
        lines (vim.api.nvim_buf_get_lines 0 (- (. s-start 2) 1) (. s-end 2) false)]
    (tset lines 1 (string.sub (. lines 1) (. s-start 3) (- 1)))
    (if (= n-lines 1)
      (tset lines n-lines
            (string.sub (. lines n-lines) 1
                        (+ (- (. s-end 3) (. s-start 3)) 1)))
      (tset lines n-lines (string.sub (. lines n-lines) 1 (. s-end 3))))
    (table.concat lines "\n")))
