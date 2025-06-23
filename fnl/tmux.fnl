(local a (require :aniseed.core))
(local str (require :aniseed.string))
(local shell (require :shell))

(fn tmux* [cmd & args]
  (let [args (a.map #(.. "'" (shell.escape-single-quotes $1) "'") args)]
    (vim.fn.system (.. "tmux " cmd " " (str.join " " args)))))

(fn tmux*-lines [cmd & args]
  (-> (tmux* cmd (unpack args))
      (str.split "\n")))

(fn send [target cmd]
  (tmux* :send :-t target cmd))

(fn submit [target cmd]
  (tmux* :send :-t target cmd :C-m))

(fn switch-to [target]
  (tmux* :switch-client :-t target))

(fn zoomed? [target]
   (-> (tmux*-lines :list-panes :-t target :-F :#F)
       (->> (a.some #(string.find $1 "Z")))
       (not= nil)))

(fn ensure-not-zoomed [target]
  (when (zoomed? target)
    (tmux* :resize-pane :-t target :Z)))

(fn ensure-not-copy-mode [target]
  (tmux* :send :-t target :-X :cancel))

{: ensure-not-copy-mode
 : ensure-not-zoomed
 : send
 : submit
 : switch-to
 : zoomed?}
