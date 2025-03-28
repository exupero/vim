(import-macros {: defcmd : defcmd0 : defcmd1} :macros)

(module kotlin
  {require {a aniseed.core
            u util}})

; Debugging

(defn logging-code [text]
  (.. "File(\"debug.log\").appendText(\""
      (-> text
          (string.gsub "\"" "\\\"")
          (string.gsub "\n" "\\n"))
      "=${" (string.gsub text "\n" " ") "}\\n\")"))

(defcmd0 KotlinLogWord []
  (u.insert-line-before-mark! :u (logging-code (vim.fn.expand :<cword>))))

(defcmd KotlinLogSelection {:nargs 0 :range true} []
  (u.insert-line-before-mark! :u (logging-code (u.visual-selection))))

; Keymappings

(vim.keymap.set :n :<Leader>d ":KotlinLogWord<CR>")

(vim.keymap.set :v :<Leader>d ":KotlinLogSelection<CR>")
