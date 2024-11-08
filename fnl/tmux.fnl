(module tmux
  {require {}})

(defn send [target cmd]
  (vim.fn.system (.. "tmux send -t " target " '" cmd "' C-m")))
