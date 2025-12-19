(import-macros {: defcmd : defcmd0 : defcmd1} :macros)

(local a (require :aniseed.core))
(local nvim (require :aniseed.nvim))
(local u (require :util))

(defcmd0 MdChunkOpen []
  (let [content (vim.fn.getline (vim.fn.line :.))
        (filename line) (string.match content "^```diff (%S+) %-%d+ %+(%d+)$")]
    (print (vim.inspect m))
    (nvim.ex.tabnew (.. :+ line) filename)))
(u.repeatable :md-chunk-open ":MdChunkOpen<CR>")
