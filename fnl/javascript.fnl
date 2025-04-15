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

(defn logging-code [text]
  (.. "console.log(\"%c%s\", "
      "\"color:mediumseagreen;font-weight:bold\", "
      "\"" (string.gsub text "\"" "\\\"") "\", "
      text ");"))

(defcmd0 JavascriptLogWordBeforeCursor []
  (u.insert-line-before-cursor! (logging-code (vim.fn.expand :<cword>))))

(defcmd0 JavascriptLogWordAfterCursor []
  (u.insert-line-after-cursor! (logging-code (vim.fn.expand :<cword>))))

(defcmd1 JavascriptLogWordBeforeMark [{:args mark}]
  (u.insert-line-before-mark! mark (logging-code (vim.fn.expand :<cword>))))

(defcmd JavascriptLogSelectionBeforeCursor {:nargs 0 :range true} []
  (u.insert-line-after-cursor! (logging-code (u.visual-selection))))

(defcmd JavascriptLogSelectionAfterCursor {:nargs 0 :range true} []
  (u.insert-line-after-cursor! (logging-code (u.visual-selection))))

(defcmd JavascriptLogSelectionBeforeMark {:nargs 1 :range true} [{:args mark}]
  (u.insert-line-before-mark! mark (logging-code (u.visual-selection))))

; Keymappings

(vim.keymap.set :n :<e "<Plug>(move-node-back)")
(vim.keymap.set :n :>e "<Plug>(move-node-forward)")
(vim.keymap.set :n :<I ":call JavascriptInsertBefore()<CR>")
(vim.keymap.set :n :>I ":call JavascriptInsertAfter()<CR>")

(vim.keymap.set :n :<Leader>c ":JavascriptLogWordBeforeCursor<CR>")
(vim.keymap.set :n :<Leader>d ":JavascriptLogWordBeforeMark u<CR>")
(vim.keymap.set :n :<Leader>w ":JavascriptLogWordAfterCursor<CR>")
(vim.keymap.set :n :<Leader>l ":call JavascriptLogAfter(expand('<cword>'))<CR>")

(vim.keymap.set :v :<Leader>c ":JavascriptLogSelectionBeforeCursor<CR>")
(vim.keymap.set :v :<Leader>d ":JavascriptLogSelectionBeforeMark u<CR>")
(vim.keymap.set :v :<Leader>w ":JavascriptLogSelectionAfterCursor<CR>")
(vim.keymap.set :v :<Leader>l ":call JavascriptLogAfter(VisualSelection())<CR>")
