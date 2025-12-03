(import-macros {: defcmd : defcmd0 : defcmd1} :macros)

(local a (require :aniseed.core))
(local str (require :aniseed.string))
(local ts (require :treesitter))
(local u (require :util))

(tset vim.opt_local :textwidth 120)
; (tset vim.opt_local :nonumber true)
; (tset vim.opt_local :norelativenumber true)

(fn ancestor-stmt [node]
  (ts.find-up node #(string.match ($1:type) "_statement$")))

(fn prepend-stmts [node stmts]
  (let [stmt (ancestor-stmt node)
        (line col) (stmt:start)
        indent (string.rep " " col)]
    (u.set-lines! line line (a.map #(.. indent $1) stmts))))

(fn append-stmts [node stmts]
  (let [stmt (ancestor-stmt node)
        (_ start-col) (stmt:start)
        indent (string.rep " " start-col)
        (line col) (stmt:end_)
        line (a.inc line)]
    (u.set-lines! line line (a.map #(.. indent $1) stmts))))

(fn log-stmt [s]
  (.. "print(f\"---"
      (string.gsub s "\"" "\\\"")
      " {repr("
      s
      ")}\")"))

(fn log-before [start end s]
  (prepend-stmts (if (and start end)
                   (ts.visual-start-node)
                   (ts.cursor-node))
                 [(log-stmt s)]))

(fn log-after [start end s]
  (append-stmts (if (and start end)
                   (ts.visual-start-node)
                   (ts.cursor-node))
                [(log-stmt s)]))

(fn debug-before []
  (prepend-stmts (ts.cursor-node)
                 ["import pdb; pdb.set_trace()"]))

(fn debug-after []
  (append-stmts (ts.cursor-node)
                ["import pdb; pdb.set_trace()"]))

(fn pickle-after [path obj]
  (append-stmts (ts.cursor-node)
                ["import pickle"
                 (.. "with open('" path "', 'wb') as picklefile:")
                 (.. "    pickle.dump(" obj ", picklefile)")]))

(fn insert-at-start [node]
  (let [(row col) (node:start)]
    (u.insert-mode!)
    (u.set-cursor! (a.inc row) (a.inc col))))

(fn insert-at-end [node]
  (let [(row col) (node:end_)]
    (u.insert-mode!)
    (u.set-cursor! (a.inc row) (a.dec col))))

(fn insert-before-stmt [stmt]
  (let [(row col) (stmt:start)]
    (u.set-lines! row row [(string.rep " " col)])
    (u.insert-mode!)
    (u.set-cursor! (a.inc row) col)))

(fn insert-after-stmt [stmt]
  (let [(_ col) (stmt:start)
        (row) (stmt:end_)
        row (a.inc row)]
    (u.set-lines! row row [(string.rep " " col)])
    (u.insert-mode!)
    (u.set-cursor! (a.inc row) col)))

(fn ancestor-paren [node]
  (a.some #(ts.ancestor-by-type node $1)
          [:tuple
           :argument_list
           :parenthesized_expression
           :parameters]))

(local insert-handlers
  [[ancestor-paren insert-at-start    insert-at-end]
   [ancestor-stmt  insert-before-stmt insert-after-stmt]])

(fn insert-before []
  (u.insert-before insert-handlers))

(fn insert-after []
  (u.insert-after insert-handlers))

(local swappable-ancestors
  [#(= ($1:type) :default_parameter)
   #(= ($1:type) :keyword_argument)
   #(= ($1:type) :keyword_separator)
   #(and (= ($1:type) :identifier)
         (ts.ancestor-by-type $1 :parameters))
   #(string.match ($1:type) "_statement$")])

(local skippable-siblings
  [#(not ($1:named))])

(fn move-node-back []
  (ts.move-node-back swappable-ancestors skippable-siblings))
(u.repeatable :move-node-back ":call PythonMoveNodeBack()<CR>")

(fn move-node-forward []
  (ts.move-node-forward swappable-ancestors skippable-siblings))
(u.repeatable :move-node-forward ":call PythonMoveNodeForward()<CR>")

(fn comments-to-docstring [start end]
  (let [lines (a.map #(-> $1
                          (: :gsub "# ?" "")
                          (: :gsub "^ *$" ""))
                     (u.get-lines (a.dec start) end))
        (left right) (string.find (a.first lines) "^ *")
        indent (string.rep " " (a.inc (- right left)))]
    (table.insert lines 1 (.. indent "\"\"\""))
    (table.insert lines (.. indent "\"\"\""))
    (u.set-lines! (a.dec start) end lines)))

(fn log-value [start end]
  (let [lines (u.get-lines (a.dec start) end)
        word (vim.fn.expand "<cword>")
        (left right) (string.find (a.first lines) "^ *")
        indent (string.rep " " (a.inc (- right left)))
        lines (a.concat
                lines
                [(.. indent "with open('log.txt', 'a') as file:")
                 (.. indent "    file.write(f'---" word "\\n{" word "}\\n')")])]
    (u.set-lines! (a.dec start) end lines)))

(fn wrap-try [start end]
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

(fn log-to-file [word]
  (vim.cmd.normal (vim.api.nvim_replace_termcodes (.. "olog<c-r>=UltiSnips#ExpandSnippet()<cr><c-n><c-n>" word) true true true)))

(fn attr-to-subscript []
  (let [node (ts.cursor-node)
        (r c1) (node:start)
        (_ c2) (node:end_)
        prefix (ts.get-text [r 0] [r (a.dec c1)])
        suffix (ts.get-text [r c2] [r 1000])
        lines (str.split (.. prefix "['" (ts.node-text node) "']" suffix) "\n")]
    (u.set-lines! r (a.inc r) lines)))
(vim.cmd "command! -nargs=0 PythonAttrToSubscript call PythonAttrToSubscript()")

; Debugging

(fn logging-code [text]
  (.. "print(f\"---{" (string.gsub text "\"" "'") "=}\")"))

(defcmd0 PythonLogWordBeforeCursor []
  (u.insert-line-before-cursor! (logging-code (vim.fn.expand :<cword>))))

(defcmd0 PythonLogWordAfterCursor []
  (u.insert-line-after-cursor! (logging-code (vim.fn.expand :<cword>))))

(defcmd1 PythonLogWordBeforeMark [{:args mark}]
  (u.insert-line-before-mark! mark (logging-code (vim.fn.expand :<cword>))))

(defcmd PythonLogSelectionBeforeCursor {:nargs 0 :range true} []
  (u.insert-line-before-cursor! (logging-code (u.visual-selection))))

(defcmd PythonLogSelectionAfterCursor {:nargs 0 :range true} []
  (u.insert-line-after-cursor! (logging-code (u.visual-selection))))

(defcmd PythonLogSelectionBeforeMark {:nargs 1 :range true} [{:args mark}]
  (u.insert-line-before-mark! mark (logging-code (u.visual-selection))))
