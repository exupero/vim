(module python
  {require {a aniseed.core
            str aniseed.string
            util aniseed.nvim.util
            ts treesitter
            u util}})

(tset vim.opt_local :textwidth 120)
; (tset vim.opt_local :nonumber true)
; (tset vim.opt_local :norelativenumber true)

(defn ancestor-stmt [node]
  (ts.find-up node #(string.match ($1:type) "_statement$")))

(defn prepend-stmts [node stmts]
  (let [stmt (ancestor-stmt node)
        (line col) (stmt:start)
        indent (string.rep " " col)]
    (u.set-lines! line line (a.map #(.. indent $1) stmts))))

(defn append-stmts [node stmts]
  (let [stmt (ancestor-stmt node)
        (_ start-col) (stmt:start)
        indent (string.rep " " start-col)
        (line col) (stmt:end_)
        line (a.inc line)]
    (u.set-lines! line line (a.map #(.. indent $1) stmts))))

(defn log-stmt [s]
  (.. "print(f\"---"
      (string.gsub s "\"" "\\\"")
      " {repr("
      s
      ")}\")"))

(defn log-before [start end s]
  (prepend-stmts (if (and start end)
                   (ts.visual-start-node)
                   (ts.cursor-node))
                 [(log-stmt s)]))
(util.fn-bridge :PythonLogBefore :python :log-before {:range true})

(defn log-after [start end s]
  (append-stmts (if (and start end)
                   (ts.visual-start-node)
                   (ts.cursor-node))
                [(log-stmt s)]))
(util.fn-bridge :PythonLogAfter :python :log-after {:range true})

(defn debug-before []
  (prepend-stmts (ts.cursor-node)
                 ["import pdb; pdb.set_trace()"]))
(util.fn-bridge :PythonDebugBefore :python :debug-before {})

(defn debug-after []
  (append-stmts (ts.cursor-node)
                ["import pdb; pdb.set_trace()"]))
(util.fn-bridge :PythonDebugAfter :python :debug-after {})

(defn pickle-after [path obj]
  (append-stmts (ts.cursor-node)
                ["import pickle"
                 (.. "with open('" path "', 'wb') as picklefile:")
                 (.. "    pickle.dump(" obj ", picklefile)")]))
(util.fn-bridge :PickleAfter :python :pickle-after {})

(defn insert-at-start [node]
  (let [(row col) (node:start)]
    (u.insert-mode!)
    (u.set-cursor! (a.inc row) (a.inc col))))

(defn insert-at-end [node]
  (let [(row col) (node:end_)]
    (u.insert-mode!)
    (u.set-cursor! (a.inc row) (a.dec col))))

(defn insert-before-stmt [stmt]
  (let [(row col) (stmt:start)]
    (u.set-lines! row row [(string.rep " " col)])
    (u.insert-mode!)
    (u.set-cursor! (a.inc row) col)))

(defn insert-after-stmt [stmt]
  (let [(_ col) (stmt:start)
        (row) (stmt:end_)
        row (a.inc row)]
    (u.set-lines! row row [(string.rep " " col)])
    (u.insert-mode!)
    (u.set-cursor! (a.inc row) col)))

(defn ancestor-paren [node]
  (a.some #(ts.ancestor-by-type node $1)
          [:tuple
           :argument_list
           :parenthesized_expression
           :parameters]))

(def insert-handlers
  [[ancestor-paren insert-at-start    insert-at-end]
   [ancestor-stmt  insert-before-stmt insert-after-stmt]])

(defn insert-before []
  (u.insert-before insert-handlers))
(util.fn-bridge :PythonInsertBefore :python :insert-before {})

(defn insert-after []
  (u.insert-after insert-handlers))
(util.fn-bridge :PythonInsertAfter :python :insert-after {})

(def swappable-ancestors
  [#(= ($1:type) :default_parameter)
   #(= ($1:type) :keyword_argument)
   #(= ($1:type) :keyword_separator)
   #(and (= ($1:type) :identifier)
         (ts.ancestor-by-type $1 :parameters))
   #(string.match ($1:type) "_statement$")])

(def skippable-siblings
  [#(not ($1:named))])

(defn move-node-back []
  (ts.move-node-back swappable-ancestors skippable-siblings))
(util.fn-bridge :PythonMoveNodeBack :python :move-node-back)
(u.repeatable :move-node-back ":call PythonMoveNodeBack()<CR>")

(defn move-node-forward []
  (ts.move-node-forward swappable-ancestors skippable-siblings))
(util.fn-bridge :PythonMoveNodeForward :python :move-node-forward)
(u.repeatable :move-node-forward ":call PythonMoveNodeForward()<CR>")

(defn comments-to-docstring [start end]
  (let [lines (a.map #(-> $1
                          (: :gsub "# ?" "")
                          (: :gsub "^ *$" ""))
                     (u.get-lines (a.dec start) end))
        (left right) (string.find (a.first lines) "^ *")
        indent (string.rep " " (a.inc (- right left)))]
    (table.insert lines 1 (.. indent "\"\"\""))
    (table.insert lines (.. indent "\"\"\""))
    (u.set-lines! (a.dec start) end lines)))
(util.fn-bridge :CommentsToDocstring :python :comments-to-docstring {:range true})

(defn log-value [start end]
  (let [lines (u.get-lines (a.dec start) end)
        word (vim.fn.expand "<cword>")
        (left right) (string.find (a.first lines) "^ *")
        indent (string.rep " " (a.inc (- right left)))
        lines (a.concat
                lines
                [(.. indent "with open('log.txt', 'a') as file:")
                 (.. indent "    file.write(f'---" word "\\n{" word "}\\n')")])]
    (u.set-lines! (a.dec start) end lines)))
(util.fn-bridge :PythonLogValue :python :log-value {:range true})

(defn wrap-try [start end]
  (let [lines (u.get-lines (a.dec start) end)
        (left right) (string.find (a.first lines) "^ *")
        indent (string.rep " " (a.inc (- right left)))
        lines (a.concat
                [(.. indent "try:")]
                (a.map #(.. "    " $1) lines)
                [(.. indent "except:")
                 (.. indent "    with open('exceptions.txt', 'a') as file:")
                 (.. indent "        file.write(traceback.format_exc())")
                 (.. indent "    raise")])]
    (u.set-lines! (a.dec start) end lines)))
(util.fn-bridge :PythonWrapTry :python :wrap-try {:range true})

(defn log-to-file [word]
  (vim.cmd.normal (vim.api.nvim_replace_termcodes (.. "olog<c-r>=UltiSnips#ExpandSnippet()<cr><c-n><c-n>" word) true true true)))
(util.fn-bridge :PythonWriteLog :python :log-to-file {})

(defn attr-to-subscript []
  (let [node (ts.cursor-node)
        (r c1) (node:start)
        (_ c2) (node:end_)
        prefix (ts.get-text [r 0] [r (a.dec c1)])
        suffix (ts.get-text [r c2] [r 1000])
        lines (str.split (.. prefix "['" (ts.node-text node) "']" suffix) "\n")]
    (u.set-lines! r (a.inc r) lines)))
(util.fn-bridge :PythonAttrToSubscript :python :attr-to-subscript {})
(vim.cmd "command! -nargs=0 PythonAttrToSubscript call PythonAttrToSubscript()")

(vim.keymap.set :n "<e" "<Plug>(move-node-back)")
(vim.keymap.set :n ">e" "<Plug>(move-node-forward)")
(vim.keymap.set :n "<I" ":call PythonInsertBefore()<CR>")
(vim.keymap.set :n ">I" ":call PythonInsertAfter()<CR>")

(vim.keymap.set :n "<Leader>c" ":call PythonLogBefore(expand('<cword>'))<CR>")
(vim.keymap.set :n "<Leader>d" ":call PythonDebugBefore()<CR>")
(vim.keymap.set :n "<Leader>l" ":call PythonWriteLog(expand('<cword>'))<CR>")

(vim.keymap.set :v "<Leader>c" ":call PythonLogBefore(VisualSelection())<CR>")
(vim.keymap.set :v "<Leader>l" ":call PythonLogAfter(VisualSelection())<CR>")

(vim.api.nvim_create_autocmd [:BufReadPost]
  {:pattern ["*.py"]
   :callback #(vim.cmd "command! -nargs=0 -range WrapTry <line1>,<line2>call PythonWrapTry()")})
(vim.api.nvim_create_autocmd [:BufReadPost]
  {:pattern ["*.py"]
   :callback #(vim.cmd "command! -nargs=0 -range LogValue <line1>,<line2>call PythonLogValue()")})
