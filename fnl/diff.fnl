(import-macros {: defcmd : defcmd0 : defcmd1} :macros)

(local a (require :aniseed.core))
(local nvim (require :aniseed.nvim))
(local u (require :util))

(fn find [start dir pred]
  (let [max (vim.fn.line :$)]
    (var line start)
    (var found false)
    (while (and (not found) (< 0 line (a.inc max)))
      (let [content (vim.fn.getline line)]
        (if (pred content)
          (set found true)
          (set line (dir line)))))
    line))

(fn find-backwards [start pred]
  (find start a.dec pred))

(fn find-forwards [start pred]
  (find start a.inc pred))

(fn file-start? [line]
  (string.match line "^diff"))

(fn chunk-start? [line]
  (string.match line "^@@"))

(fn _G.diff_fold_level [line]
  (let [line (vim.fn.getline (or line vim.v.lnum))]
    (if
      (file-start? line) :>1
      (chunk-start? line) :>2
      :=)))

(fn _G.diff_fold_text []
  (let [line (vim.fn.getline vim.v.foldstart)
        count (+ 1 (- vim.v.foldend vim.v.foldstart))
        level (_G.diff_fold_level vim.v.foldstart)
        prefix (case level
                 (where :>1) ""
                 (where :>2) "▶ "
                 _  "")]
    (.. prefix line " (" count " lines)")))

; Commands

(defcmd0 DiffChunkDelete []
  (let [start (find-backwards (vim.fn.line :.) chunk-start?)
        end (find-forwards (a.inc start) #(or (chunk-start? $1) (file-start? $1)))]
    (u.set-lines! (a.dec start) (a.dec end) [])
    (u.set-cursor! start 0)))
(u.repeatable :diff-chunk-delete ":DiffChunkDelete<CR>")

(defcmd0 DiffFileCopy []
  (let [start (find-backwards (vim.fn.line :.) file-start?)
        end (find-forwards (a.inc start) file-start?)
        lines (u.get-lines (a.dec start) (a.dec end))]
    (vim.fn.setreg "\"" lines :l)))
(u.repeatable :diff-file-copy ":DiffFileCopy<CR>")

(defcmd0 DiffFileDelete []
  (let [start (find-backwards (vim.fn.line :.) file-start?)
        end (find-forwards (a.inc start) file-start?)]
    (u.set-lines! (a.dec start) (a.dec end) [])
    (u.set-cursor! (a.dec start) 0)))
(u.repeatable :diff-file-delete ":DiffFileDelete<CR>")

(defcmd0 DiffFileOpen []
  (let [start (find-backwards (vim.fn.line :.) file-start?)
        line (vim.fn.getline start)
        filename (string.match line "^diff %-%-git a/%S+ b/(%S+)$")]
    (nvim.ex.tabnew filename)))
(u.repeatable :diff-file-open ":DiffFileOpen<CR>")

(defcmd DiffNote {:range true} []
  (let [selected (u.visual-lines)
        [_ start] (vim.fn.getpos "'<")
        [_ end] (vim.fn.getpos "'>")]
    (table.insert selected 1 "v")
    (table.insert selected "^")
    (table.insert selected "")
    (table.insert selected "x")
    (u.set-lines! (a.dec start) end selected)
    (u.set-cursor! (+ 3 end) 0)
    (u.insert-mode!)))
