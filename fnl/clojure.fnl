(import-macros {: defcmd} :macros)

(module clojure
  {require {a aniseed.core
            nvim aniseed.nvim
            util aniseed.nvim.util
            u util
            ts treesitter}
   autoload {client conjure.client
             eval conjure.eval}})

(defcmd TestFile {:nargs 0} [_]
  (vim.cmd "silent! write")
  (eval.eval-str {:origin :dotfiles
                  :code "(do
                           (require '[babashka.deps :as deps])
                           (deps/add-deps '{:deps {io.github.matthewdowney/rich-comment-tests {:mvn/version \"v1.0.3\"}}})
                           (require 'com.mjdowney.rich-comment-tests)
                           (binding [clojure.test/*test-out* *out*]
                             (com.mjdowney.rich-comment-tests/run-ns-tests! *ns*)))"}))

(defcmd ToggleParinfer {:nargs 0} [_]
  (if (= vim.g.parinfer_mode "smart")
    (tset vim.g :parinfer_mode "paren")
    (tset vim.g :parinfer_mode "smart")))

(defcmd ConjureLogPane {:nargs 0} [_]
  (vim.cmd "ConjureLogVSplit")
  (vim.cmd "set wrap"))

(defn eval-query-match! [q]
  (let [root (-> (vim.treesitter.get_parser 0)
                 (: :parse)
                 a.first
                 (: :root))
        q (vim.treesitter.query.parse "clojure" q)]
    (each [i m _ (q:iter_matches root 0 0 -1)]
      (each [id node (pairs m)]
        (when (= "eval" (. q.captures id))
          (eval.eval-str {:origin :dotfiles
                          :code (vim.treesitter.get_node_text node 0)}))))))

(defcmd UpdateRequires {:nargs 0} [_]
  (u.update-file-and-move-cursor! #(vim.fn.execute "%!update-requires"))
  (eval-query-match! "((source (list_lit . value: (sym_lit) @f) @eval) (#any-of? @f \"ns\" \"deps/add-deps\" \"require\"))"))

(tset vim.g :conjure#mapping#log_vsplit :lc)
(vim.keymap.set :n :<LocalLeader>c ":ConjureConnect<CR>")
(vim.keymap.set :n :<LocalLeader>lv ":ConjureLogPane<CR>")
(vim.keymap.set :n :<LocalLeader>p ":ToggleParinfer<CR>")
(vim.keymap.set :n :<LocalLeader>t ":TestFile<CR>")
(vim.keymap.set :n :<LocalLeader>u ":UpdateRequires<CR>")

(vim.keymap.set :n :<p ":call CocActionAsync('runCommand', 'lsp-clojure-drag-backward')<CR>" {:buffer true})
(vim.keymap.set :n :>p ":call CocActionAsync('runCommand', 'lsp-clojure-drag-forward')<CR>" {:buffer true})
