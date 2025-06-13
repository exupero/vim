(local str (require :aniseed.string))
(local util (require :aniseed.nvim.util))

(fn root []
  (let [(dir) (str.trim (vim.fn.system "git rev-parse --show-toplevel"))]
    dir))

(fn repo-path [path]
  (str.trim (vim.fn.system (.. "git path " path))))

{: root
 : repo-path}
