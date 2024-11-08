(module typescript
  {require {a aniseed.core
            util aniseed.nvim.util
            u util
            j javascript
            ts treesitter}})

(defn ancestor-stmt [node]
  (ts.find-up node #(string.match ($1:type) "_statement$")))

(defn prepend-stmts [stmts]
  (let [[line] (u.get-cursor)
        [cur] (u.get-lines (a.dec line) line)
        indent ((cur:gmatch "(%s*)"))
        line (a.dec line)]
    (u.set-lines! line line (a.map #(.. indent $1) stmts))))

(defn append-stmts [stmts]
  (let [[line] (u.get-cursor)
        ; get the indent of the line after the current line
        [cur] (u.get-lines line (a.inc line))
        indent ((cur:gmatch "(%s*)"))]
    (u.set-lines! line line (a.map #(.. indent $1) stmts))))

(defn debug-before [start end s]
  (prepend-stmts ["debugger;"]))
(util.fn-bridge :TypescriptDebugBefore :typescript :debug-before {:range true})

(defn log-before [start end s]
  (prepend-stmts [(j.log-stmt s)]))
(util.fn-bridge :TypescriptLogBefore :typescript :log-before {:range true})

(defn log-after [start end s]
  (append-stmts [(j.log-stmt s)]))
(util.fn-bridge :TypescriptLogAfter :typescript :log-after {:range true})

(defn log-expr [start end s]
  (let [[buf start-row start-col] (vim.fn.getpos "'<")
        [_ end-row end-col] (vim.fn.getpos "'>")]
    (vim.api.nvim_buf_set_text buf (a.dec start-row) (a.dec start-col) (a.dec end-row) end-col
                               (j.log-expr s))
    (u.set-cursor! start-row (a.dec start-col))))
(util.fn-bridge :TypescriptLogExpr :typescript :log-expr {:range true})

(vim.keymap.set :n "<Leader>c" ":call TypescriptLogBefore(expand('<cword>'))<CR>")
(vim.keymap.set :n "<Leader>d" ":call TypescriptDebugBefore()<CR>")
(vim.keymap.set :n "<Leader>l" ":call TypescriptLogAfter(expand('<cword>'))<CR>")

(vim.keymap.set :v "<Leader>c" ":call TypescriptLogBefore(VisualSelection())<CR>")
(vim.keymap.set :v "<Leader>e" ":call TypescriptLogExpr(VisualSelection())<CR>")
(vim.keymap.set :v "<Leader>l" ":call TypescriptLogAfter(VisualSelection())<CR>")
