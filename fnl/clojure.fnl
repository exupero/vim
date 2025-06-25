(import-macros {: defcmd} :macros)

(local a (require :aniseed.core))
(local nvim (require :aniseed.nvim))
(local util (require :aniseed.nvim.util))
(local u (require :util))
(local ts (require :treesitter))
(local {: autoload} (require :nfnl.module))
(local client (autoload :conjure.client))
(local eval (autoload :conjure.eval))

(defcmd TestFile {:nargs 0} [_]
  (vim.cmd "silent! write")
  (eval.eval-str {:origin :dotfiles
                  :code "(do
                           (require '[babashka.deps :as deps])
                           (deps/add-deps '{:deps {io.github.matthewdowney/rich-comment-tests {:mvn/version \"v1.0.3\"}}})
                           (require 'com.mjdowney.rich-comment-tests)
                           (binding [clojure.test/*test-out* *out*]
                             (com.mjdowney.rich-comment-tests/run-ns-tests! *ns*)))"}))

(defcmd ParinferToggle {:nargs 0} [_]
  (if (= vim.g.parinfer_mode "smart")
    (tset vim.g :parinfer_mode "paren")
    (tset vim.g :parinfer_mode "smart")))

(defcmd ConjureLogHPane {:nargs 0} [_]
  (vim.cmd "ConjureLogSplit")
  (vim.cmd "setlocal wrap"))

(defcmd ConjureLogVPane {:nargs 0} [_]
  (vim.cmd "ConjureLogVSplit")
  (vim.cmd "setlocal wrap"))

(fn eval-query-match! [q]
  (let [root (-> (vim.treesitter.get_parser 0)
                 (: :parse)
                 a.first
                 (: :root))
        q (vim.treesitter.query.parse "clojure" q)]
    (each [i m _ (q:iter_matches root 0 0 -1)]
      (each [id node (pairs m)]
        (when (= "eval" (. q.captures id))
          (eval.eval-str {:origin :dotfiles
                          :code (vim.treesitter.get_node_text (a.first node) 0)}))))))

(defcmd UpdateRequires {:nargs 0} [_]
  (u.update-file-and-move-cursor! #(vim.fn.execute "%!update-requires"))
  (eval-query-match! "((source (list_lit . value: (sym_lit) @f) @eval) (#any-of? @f \"ns\" \"deps/add-deps\" \"require\"))"))

(tset vim.g :conjure#mapping#log_split "")
(tset vim.g :conjure#mapping#log_vsplit "")
(vim.keymap.set :n :<LocalLeader>c ":ConjureConnect<CR>")
(vim.keymap.set :n :<LocalLeader>ls ":ConjureLogHPane<CR>")
(vim.keymap.set :n :<LocalLeader>lv ":ConjureLogVPane<CR>")
(vim.keymap.set :n :<LocalLeader>p ":ParinferToggle<CR>")
(vim.keymap.set :n :<LocalLeader>t ":TestFile<CR>")
(vim.keymap.set :n :<LocalLeader>u ":UpdateRequires<CR>")

(vim.keymap.set :n :<p ":call CocActionAsync('runCommand', 'lsp-clojure-drag-backward')<CR>" {:buffer true})
(vim.keymap.set :n :>p ":call CocActionAsync('runCommand', 'lsp-clojure-drag-forward')<CR>" {:buffer true})
