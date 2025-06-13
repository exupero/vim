(local a (require :aniseed.core))
(local nvim (require :aniseed.nvim))
(local util (require :aniseed.nvim.util))
(local str (require :aniseed.string))

(fn node-at-position [row col]
  (-> (vim.treesitter.get_parser 0)
      (: :parse)
      a.first
      (: :root)
      (: :descendant_for_range (a.dec row) col (a.dec row) col)))

(fn cursor-node []
  (let [[row col] (vim.api.nvim_win_get_cursor 0)]
    (node-at-position row col)))

(fn range-node []
  (let [[_ start-row start-col] (vim.fn.getpos "'<")
        [_ end-row end-col] (vim.fn.getpos "'>")]
    (-> (vim.treesitter.get_parser 0)
        (: :parse)
        a.first
        (: :root)
        (: :descendant_for_range (a.dec start-row) start-col (a.dec end-row) end-col))))

(fn node-text [node]
  (vim.treesitter.get_node_text node 0))

(fn find-node [node pred step]
  (var n node)
  (while (and n (not (pred n)))
    (set n (step n)))
  n)

(fn find-back [node pred]
  (find-node (node:prev_sibling) pred #($1:prev_sibling)))

(fn find-forward [node pred]
  (find-node (node:next_sibling) pred #($1:next_sibling)))

(fn find-up [node pred]
  (find-node node pred #($1:parent)))

(fn ancestor-by-type [node k]
  (find-up node #(= k ($1:type))))

(fn insert-before [handlers]
  (let [node (cursor-node)
        [parent before] (a.some (fn [matcher]
                                  (let [[f before] matcher]
                                    (match (f node)
                                      parent [parent before])))
                                handlers)]
    (before parent)))

(fn insert-after [handlers]
  (let [node (cursor-node)
        [parent after] (a.some (fn [matcher]
                                 (let [[f _ after] matcher]
                                   (match (f node)
                                     parent [parent after])))
                               handlers)]
    (after parent)))

(fn get-text [[r1 c1] [r2 c2]]
  (let [lines (u.get-lines r1 (a.inc r2))]
    (tset lines (length lines) (string.sub (a.last lines) 0 c2))
    (tset lines 1 (string.sub (a.first lines) (a.inc c1)))
    (table.concat lines "\n")))

(fn swap-nodes [before after]
  (let [(r1 c1) (before:start)
        (r2 c2) (before:end_)
        (r3 c3) (after:start)
        (r4 c4) (after:end_)
        t1 (node-text before)
        t2 (get-text [r2 c2] [r3 c3])
        t3 (node-text after)
        prefix (get-text [r1 0] [r1 c1])
        suffix (get-text [r4 c4] [r4 1000])
        lines (str.split (.. prefix t3 t2 t1 suffix) "\n")]
    (u.set-lines! r1 (a.inc r4) lines)
    [[r1 c1] [r2 c2] [r3 c3] [r4 c4]]))

(fn move-node-back [swappable skippable]
  (let [node (cursor-node)
        ancestor (a.some #(find-up node $1) swappable)]
    (match (find-back ancestor (fn [n] (not (a.some #($1 n) skippable))))
      prev (let [[[r1 c1]] (swap-nodes prev ancestor)]
             (u.set-cursor! (a.inc r1) c1)))))

(fn move-node-forward [swappable skippable]
  (let [node (cursor-node)
        ancestor (a.some #(find-up node $1) swappable)]
    (match (find-forward ancestor (fn [n] (not (a.some #($1 n) skippable))))
      next (let [[[r1 c1] [r2 c2] [r3 c3] [r4 c4]] (swap-nodes ancestor next)]
             (u.set-cursor! (a.inc (+ r1 (- r4 r2)))
                            (if (= r1 r3)
                              (+ c1 (- c4 c2))
                              c3))))))

(fn visual-start-node []
  (let [[_ row col] (vim.fn.getpos "'<")]
    (node-at-position row col)))

(fn replace-node [node replacement]
  (let [(start-row start-col end-row end-col) (node:range)]
    (vim.api.nvim_buf_set_text 0 start-row start-col end-row end-col [replacement])))

{: node-at-position
 : cursor-node
 : range-node
 : node-text
 : find-node
 : find-back
 : find-forward
 : find-up
 : ancestor-by-type
 : insert-before
 : insert-after
 : get-text
 : swap-nodes
 : move-node-back
 : move-node-forward
 : visual-start-node
 : replace-node}
