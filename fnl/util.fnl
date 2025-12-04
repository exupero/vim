(local a (require :aniseed.core))
(local str (require :aniseed.string))
(local ts (require :treesitter))

(fn ifilter [pred iter]
  (let [result []]
    (each [i iter]
      (if (pred i)
        (table.insert result i)))
    result))

(fn split-lines [s]
  (str.split s "\n"))

(fn get-lines [start-row end-row]
  (vim.api.nvim_buf_get_lines 0 start-row end-row true))

(fn get-all-lines []
  (let [lines (vim.api.nvim_buf_get_lines 0 0 (vim.api.nvim_buf_line_count 0) false)]
    (table.concat lines "\n")))

(fn get-current-line []
  (vim.api.nvim_get_current_line))

(fn set-lines! [start-row end-row lines]
  (vim.api.nvim_buf_set_lines 0 start-row end-row true lines))

(fn get-cursor []
  (vim.api.nvim_win_get_cursor 0))

(fn set-cursor! [row col]
  (vim.api.nvim_win_set_cursor 0 [row col]))

(fn update-line! [f]
  (let [[row] (vim.api.nvim_win_get_cursor 0)
        [line] (get-lines (a.dec row) row)
        (replacement) (f line)]
    (set-lines! (a.dec row) row [replacement])))

(fn update-all-lines! [f]
  (let [lines (get-lines 0 -1)]
    (each [i line (ipairs lines)]
      (tset lines i (or (f line) line)))
    (set-lines! 0 -1 lines)))

(fn insert-mode! []
  (vim.cmd "startinsert"))

(fn repeatable [nm cmd]
   (vim.keymap.set :n (.. "<Plug>(" nm ")") (.. cmd ":silent! call repeat#set(\"\\<Plug>(" nm ")\")<CR>")))

(fn update-file-and-move-cursor! [f]
  (let [line-count (vim.api.nvim_buf_line_count 0)
        [row col] (vim.api.nvim_win_get_cursor 0)]
    (f)
    (let [new-line-count (vim.api.nvim_buf_line_count 0)
          diff (- new-line-count line-count)]
      (vim.api.nvim_win_set_cursor 0 [(+ row diff) col]))))

(fn indent-at-line [row]
  (let [[line] (get-lines (a.dec row) row)]
    (string.match line "(%s+)")))

(fn insert-lines-at! [[row col] lines]
  (set-lines! row row lines))

(fn insert-lines! [lines]
  (insert-lines-at! (get-cursor) lines))

(fn insert-line-at-location! [row line indent]
  (insert-lines-at! [(a.dec row) 0] [(.. indent line)]))

(fn insert-line-before-cursor! [line]
  (let [[row] (vim.api.nvim_win_get_cursor 0)]
    (insert-line-at-location! row line (indent-at-line row))))

(fn insert-line-after-cursor! [line]
  (let [[row] (vim.api.nvim_win_get_cursor 0)]
    (insert-line-at-location! (a.inc row) line
                              (or (indent-at-line (a.inc row))
                                  (indent-at-line row)))))

(fn insert-line-before-mark! [mark line]
  (let [[row] (vim.api.nvim_buf_get_mark 0 mark)]
    (insert-line-at-location! row line (indent-at-line row))))

; https://neovim.discourse.group/t/function-that-return-visually-selected-text/1601
(fn visual-selection []
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

(fn distinct [coll]
  (let [items []
        seen {}]
    (each [_ item (ipairs coll)]
      (when (not (. seen item))
        (table.insert items item)
        (tset seen item true)))
    items))

(fn folds []
  (let [fs []]
    (for [line 1 (vim.fn.line :$)]
      (if (not= -1 (vim.fn.foldclosed line))
        (table.insert fs line)))
    fs))

(fn set-folds! [folds]
  (vim.cmd "normal! zR")
  (each [_ line (ipairs folds)]
    (if (not= -1 (vim.fn.foldclosed line))
      (vim.fn.cursor line 1)
      (vim.cmd "normal! zc"))))

; Use _G so it can be accessed by a macro
(fn _G.reload_keep_view []
  (let [view (vim.fn.winsaveview)
        fs (folds)]
    (vim.fn.execute "edit")
    (set-folds! fs)
    (vim.fn.winrestview view)))

{: ifilter
 : split-lines
 : get-lines
 : get-all-lines
 : get-current-line
 : set-lines!
 : get-cursor
 : set-cursor!
 : update-line!
 : update-all-lines!
 : insert-mode!
 : repeatable
 : update-file-and-move-cursor!
 : indent-at-line
 : insert-lines!
 : insert-line-at-location!
 : insert-line-before-cursor!
 : insert-line-after-cursor!
 : insert-line-before-mark!
 : visual-selection
 : distinct}
