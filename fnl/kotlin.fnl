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

(defcmd0 KotlinLogWordBeforeCursor []
  (u.insert-line-before-cursor! (logging-code (vim.fn.expand :<cword>))))

(defcmd0 KotlinLogWordAfterCursor []
  (u.insert-line-after-cursor! (logging-code (vim.fn.expand :<cword>))))

(defcmd1 KotlinLogWordBeforeMark [{:args mark}]
  (u.insert-line-before-mark! mark (logging-code (vim.fn.expand :<cword>))))

(defcmd KotlinLogSelectionBeforeCursor {:nargs 0 :range true} []
  (u.insert-line-before-cursor! (logging-code (u.visual-selection))))

(defcmd KotlinLogSelectionAfterCursor {:nargs 0 :range true} []
  (u.insert-line-after-cursor! (logging-code (u.visual-selection))))

(defcmd KotlinLogSelectionBeforeMark {:nargs 1 :range true} [{:args mark}]
  (u.insert-line-before-mark! mark (logging-code (u.visual-selection))))

; Keymappings

(vim.keymap.set :n :<Leader>c ":KotlinLogWordBeforeCursor<CR>")
(vim.keymap.set :n :<Leader>d ":KotlinLogWordBeforeMark u<CR>")
(vim.keymap.set :n :<Leader>w ":KotlinLogWordAfterCursor<CR>")
(vim.keymap.set :n :<Leader>l ":call KotlinLogAfter(expand('<cword>'))<CR>")

(vim.keymap.set :v :<Leader>c ":KotlinLogSelectionBeforeCursor<CR>")
(vim.keymap.set :v :<Leader>d ":KotlinLogSelectionBeforeMark u<CR>")
(vim.keymap.set :v :<Leader>w ":KotlinLogSelectionAfterCursor<CR>")
(vim.keymap.set :v :<Leader>l ":call KotlinLogAfter(VisualSelection())<CR>")
