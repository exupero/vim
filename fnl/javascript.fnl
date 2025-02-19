(import-macros {: defcmd : defcmd0 : defcmd1} :macros)

(module javascript
  {require {a aniseed.core
            str aniseed.string
            util aniseed.nvim.util
            ts treesitter
            u util}})

(defn insert-at-start [node]
  (let [(row col) (node:start)
        [line] (u.get-lines row (a.inc row))]
    (u.insert-mode!)
    (u.set-cursor! (a.inc row) (a.inc col))))

(defn insert-at-end [node offset]
  (let [(row col) (node:end_)
        [line] (u.get-lines row (a.inc row))]
    (u.insert-mode!)
    (u.set-cursor! (a.inc row) (+ (a.dec col) offset))))

(def insert-handlers
  [[#(ts.ancestor-by-type $1 :jsx_text)                 insert-at-start #(insert-at-end $1 1)]
   [#(ts.ancestor-by-type $1 :jsx_self_closing_element) insert-at-start #(insert-at-end $1 -1)]
   [#(ts.ancestor-by-type $1 :jsx_opening_element)      insert-at-start #(insert-at-end $1 0)]])

(def swappable-ancestors
  [#(= ($1:type) :jsx_text)
   #(= ($1:type) :jsx_attribute)
   #(= ($1:type) :jsx_element)])

(def skippable-siblings
  [#(not ($1:named))
   #(and (= ($1:type) :jsx_text) (str.blank? (ts.node-text $1)))])

; Refactoring

(defcmd0 JavascriptFunctionToConst []
  (let [node (ts.ancestor-by-type (ts.cursor-node) :function_declaration)
        (r1 c1) (node:start)
        (r2 c2) (node:end_)
        [name] (node:field :name)
        [params] (node:field :parameters)
        indent (string.rep " " c1)
        ; TODO this doesn't account for functions whose parameters spread over
        ; multiple lines. To fix that, get `(node:field :body)` and the start
        ; row of its first node and the end row of its last node. Also, you'll
        ; need to split the text of `params` into separate lines.
        lines (u.get-lines (a.inc r1) r2)]
    (table.insert lines 1 (.. indent "const " (ts.node-text name) " = " (ts.node-text params) " => {"))
    (table.insert lines (.. indent "};"))
    (u.set-lines! r1 (a.inc r2) lines)
    (u.set-cursor! (a.inc r1) c1)))

(defcmd0 JavascriptInsertBefore []
  (u.insert-before insert-handlers))

(defcmd0 JavascriptInsertAfter []
  (u.insert-after insert-handlers))

(defcmd0 JavascriptMoveNodeBack []
  (ts.move-node-back swappable-ancestors skippable-siblings))
(u.repeatable :move-node-back ":call JavascriptMoveNodeBack()<CR>")

(defcmd0 JavascriptMoveNodeForward []
  (ts.move-node-forward swappable-ancestors skippable-siblings))
(u.repeatable :move-node-forward ":call JavascriptMoveNodeForward()<CR>")

; Debugging

(defn log-text-code [text]
  (.. "console.log(\"%c%s\", "
      "\"color:mediumseagreen;font-weight:bold\", "
      "\"" (string.gsub text "\"" "\\\"") "\", "
      text ");"))

(defn log-text-at! [mark text]
  (let [[row] (vim.api.nvim_buf_get_mark 0 mark)
        [line] (u.get-lines (a.dec row) row)]
    (u.insert-lines-at!
      [(a.dec row) 0]
      [(.. (string.match line "(%s+)")
           (log-text-code text))])))

(defcmd0 JavascriptLogWord []
  (log-text-at! :u (vim.fn.expand :<cword>)))

(defcmd JavascriptLogSelection {:nargs 0 :range true} []
  (log-text-at! :u (u.visual-selection)))

; Keymappings

(vim.keymap.set :n :<e "<Plug>(move-node-back)")
(vim.keymap.set :n :>e "<Plug>(move-node-forward)")
(vim.keymap.set :n :<I ":call JavascriptInsertBefore()<CR>")
(vim.keymap.set :n :>I ":call JavascriptInsertAfter()<CR>")

(vim.keymap.set :n :<Leader>c ":call JavascriptLogBefore(expand('<cword>'))<CR>")
(vim.keymap.set :n :<Leader>d ":JavascriptLogWord<CR>")
(vim.keymap.set :n :<Leader>l ":call JavascriptLogAfter(expand('<cword>'))<CR>")

(vim.keymap.set :v :<Leader>c ":call JavascriptLogBefore(VisualSelection())<CR>")
(vim.keymap.set :v :<Leader>d ":JavascriptLogSelection<CR>")
(vim.keymap.set :v :<Leader>l ":call JavascriptLogAfter(VisualSelection())<CR>")
