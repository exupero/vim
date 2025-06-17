(local shell (require :shell))

(fn send [target cmd]
  (vim.fn.system (.. "tmux send -t " target " '" (shell.escape-single-quotes cmd) "'")))

(fn submit [target cmd]
  (vim.fn.system (.. "tmux send -t " target " '" (shell.escape-single-quotes cmd) "' C-m")))

(fn switch-to [target]
  (vim.fn.system (.. "tmux switch-client -t " target)))

{: send
 : submit
 : switch-to}
