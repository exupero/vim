(import-macros {: defcmd : defcmd0 : defcmd1} :macros)

(local a (require :aniseed.core))
(local nvim (require :aniseed.nvim))
(local u (require :util))

(defcmd0 MdChunkOpen []
  (let [content (vim.fn.getline (vim.fn.line :.))
        (filename line) (string.match content "^```diff (%S+) %-%d+ %+(%d+)$")]
    (nvim.ex.tabnew (.. :+ line) filename)))
(u.repeatable :md-chunk-open ":MdChunkOpen<CR>")

(defcmd1 MdDiffComments [{:args source}]
  (vim.fn.execute (.. "read! cat " source " | diff-comments")))

(fn heading? [line]
  (string.match line "^#+ "))

(defcmd0 MdReview [_]
  (let [start (u.find-backwards (vim.fn.line :.) heading?)
        lines (u.get-lines start -1)
        link (vim.fn.system :md-review (table.concat lines "\n"))]
    (u.set-lines! -1 -1 ["" link])))
