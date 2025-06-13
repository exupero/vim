(fn send [target cmd]
  (vim.fn.system (.. "tmux send -t " target " '" cmd "'")))

(fn submit [target cmd]
  (vim.fn.system (.. "tmux send -t " target " '" cmd "' C-m")))

{: send
 : submit}
