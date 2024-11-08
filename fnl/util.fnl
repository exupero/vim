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

(defn insert-mode! []
  (vim.cmd "startinsert"))

(defn repeatable [nm cmd]
   (vim.keymap.set :n (.. "<Plug>(" nm ")") (.. cmd ":silent! call repeat#set(\"\\<Plug>(" nm ")\")<CR>")))

(defn update-file-and-reposition-cursor! [f]
  (let [line-count (vim.api.nvim_buf_line_count 0)
        [row col] (vim.api.nvim_win_get_cursor 0)]
    (f)
    (let [new-line-count (vim.api.nvim_buf_line_count 0)
          diff (- new-line-count line-count)]
      (vim.api.nvim_win_set_cursor 0 [(+ row diff) col]))))
