(module git
  {require {str aniseed.string
            util aniseed.nvim.util}})

(defn root []
  (let [(dir) (str.trim (vim.fn.system "git rev-parse --show-toplevel"))]
    dir))

(defn repo-path [path]
  (str.trim (vim.fn.system (.. "git path " path))))
