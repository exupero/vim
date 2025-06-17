(fn escape [s]
  (string.gsub s "'" "'\"'\"'"))

(fn send [target cmd]
  (vim.fn.system (.. "tmux send -t " target " '" (escape cmd) "'")))

(fn submit [target cmd]
  (vim.fn.system (.. "tmux send -t " target " '" (escape cmd) "' C-m")))

(fn switch-to [target]
  (vim.fn.system (.. "tmux switch-client -t " target)))

{: send
 : submit
 : switch-to}
