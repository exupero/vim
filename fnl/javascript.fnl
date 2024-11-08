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

(defn insert-before []
  (u.insert-before insert-handlers))
(util.fn-bridge :JavascriptInsertBefore :javascript :insert-before {})

(defn insert-after []
  (u.insert-after insert-handlers))
(util.fn-bridge :JavascriptInsertAfter :javascript :insert-after {})

(def swappable-ancestors
  [#(= ($1:type) :jsx_text)
   #(= ($1:type) :jsx_attribute)
   #(= ($1:type) :jsx_element)])

(def skippable-siblings
  [#(not ($1:named))
   #(and (= ($1:type) :jsx_text) (str.blank? (ts.node-text $1)))])

(defn move-node-back []
  (ts.move-node-back swappable-ancestors skippable-siblings))
(util.fn-bridge :JavascriptMoveNodeBack :javascript :move-node-back {})
(u.repeatable :move-node-back ":call JavascriptMoveNodeBack()<CR>")

(defn move-node-forward []
  (ts.move-node-forward swappable-ancestors skippable-siblings))
(util.fn-bridge :JavascriptMoveNodeForward :javascript :move-node-forward {})
(u.repeatable :move-node-forward ":call JavascriptMoveNodeForward()<CR>")

(defn fn->const []
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
(util.fn-bridge :FnToConst :javascript :fn->const {})

(defn log-stmt [s]
  (let [s (string.gsub s "\"" "\\\"")]
    (.. "console.log(\"%c%s\", "
        "\"color:mediumseagreen\", "
        "\"" s "\"); console.log(" s ");")))

(defn log-expr [s]
  (let [src (string.gsub s "\n" "\\n")]
    (str.split
      (.. "(x=>{console.log(\"%c%s\", "
          "\"color:mediumseagreen\", "
          "\"" src "\"); console.log(x); return x})(" s ")")
      "\n")))

(util.fn-bridge :JavascriptLogBefore :javascript :log-before {:range true})

(vim.cmd "command! -nargs=0 FnToConst call FnToConst()")

(vim.keymap.set :n "<e" "<Plug>(move-node-back)")
(vim.keymap.set :n ">e" "<Plug>(move-node-forward)")
(vim.keymap.set :n "<I" ":call JavascriptInsertBefore()<CR>")
(vim.keymap.set :n ">I" ":call JavascriptInsertAfter()<CR>")

(vim.keymap.set :n "<Leader>c" ":call JavascriptLogBefore(expand('<cword>'))<CR>")
(vim.keymap.set :n "<Leader>d" ":call JavascriptDebugBefore()<CR>")
(vim.keymap.set :n "<Leader>l" ":call JavascriptLogAfter(expand('<cword>'))<CR>")

(vim.keymap.set :v "<Leader>c" ":call JavascriptLogBefore(VisualSelection())<CR>")
(vim.keymap.set :v "<Leader>l" ":call JavascriptLogAfter(VisualSelection())<CR>")
