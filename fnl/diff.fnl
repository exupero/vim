(import-macros {: defcmd : defcmd0 : defcmd1} :macros)

(local a (require :aniseed.core))
(local u (require :util))

(fn find [start dir pred]
  (let [max (vim.fn.line :$)]
    (var line start)
    (var found false)
    (while (and (not found) (< 0 line max))
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

(defcmd0 DiffCopyCurrentFile []
  (let [start (find-backwards (vim.fn.line :.) file-start?)
        end (find-forwards (a.inc start) file-start?)
        lines (u.get-lines start (a.dec end))]
    (vim.fn.setreg :0 lines :l)))

(defcmd0 DiffDeleteCurrentChunk []
  (let [start (find-backwards (vim.fn.line :.) chunk-start?)
        end (find-forwards (a.inc start) #(or (chunk-start? $1) (file-start? $1)))]
    (u.set-lines! (a.dec start) (a.dec end) [])
    (u.set-cursor! start 0)))

(defcmd0 DiffDeleteCurrentFile []
  (let [start (find-backwards (vim.fn.line :.) file-start?)
        end (find-forwards (a.inc start) file-start?)]
    (u.set-lines! (a.dec start) (a.dec end) [])
    (u.set-cursor! start 0)))
