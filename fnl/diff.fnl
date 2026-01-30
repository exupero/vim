(import-macros {: defcmd : defcmd0 : defcmd1} :macros)

(local a (require :aniseed.core))
(local nvim (require :aniseed.nvim))
(local u (require :util))

(fn file-start? [line]
  (string.match line "^diff"))

(fn chunk-start? [line]
  (string.match line "^@@"))

(fn without-comments [lines]
  (let [new-lines []]
    (var comment? false)
    (each [_ line (pairs lines)]
      (if
        (and (not comment?) (string.match line "^v$")) (set comment? true)
        (and comment? (string.match line "^x$")) (set comment? false)
        (not comment?) (table.insert new-lines line)))
    new-lines))

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
  (let [start (u.find-backwards (vim.fn.line :.) chunk-start?)
        end (u.find-forwards (a.inc start) #(or (chunk-start? $1) (file-start? $1)))
        lines (u.get-lines (a.dec start) (a.dec end))]
    (vim.fn.setreg "" lines :l)
    (u.set-lines! (a.dec start) (a.dec end) [])
    (u.set-cursor! (math.min start (vim.fn.line :$)) 0)))
(u.repeatable :diff-chunk-delete ":DiffChunkDelete<CR>")

(defcmd0 DiffChunkOpen []
  (let [line (vim.fn.line :.)
        file-start (u.find-backwards line file-start?)
        filename (string.match (vim.fn.getline file-start) "^diff %-%-git a/%S+ b/(%S+)$")
        chunk-start (u.find-backwards line chunk-start?)
        revised-start (string.match (vim.fn.getline chunk-start) "^@@ %-%d+,%d+ %+(%d+),%d+ @@")
        diff-lines (without-comments (u.get-lines (a.dec chunk-start) (a.dec line)))
        revised-line-count (a.count (a.filter #(not (string.match $1 "^-")) diff-lines))
        current-line (+ revised-start revised-line-count)]
    (nvim.ex.tabnew (.. :+ (a.dec current-line)) filename)))
(u.repeatable :diff-chunk-open ":DiffChunkOpen<CR>")

(fn comments? [lines]
  (a.some #(string.match $1 "^v$") lines))

(defcmd1 DiffChunkMove [{:args dest}]
  (let [file-start (u.find-backwards (vim.fn.line :.) file-start?)
        start (u.find-backwards (vim.fn.line :.) chunk-start?)
        end (u.find-forwards (a.inc start) #(or (chunk-start? $1) (file-start? $1)))
        lines (u.get-lines (a.dec start) (a.dec end))]
    (when (comments? lines)
      (let [header-lines (u.get-lines (a.dec file-start) (+ 3 file-start))
            lines (a.concat header-lines lines)]
        (vim.fn.writefile lines dest :a)))
    (u.set-lines! (a.dec start) (a.dec end) [])
    (u.set-cursor! (math.min start (vim.fn.line :$)) 0)))
(u.repeatable :diff-chunk-move-to-commented ":DiffChunkMove .commented.diff<CR>")

(fn parse-chunk-header [line]
  (case (string.match line "^@@ %-(%d+),(%d+) %+(%d+),(%d+) @@ %(was (.+)%)")
    (original-start original-count revised-start revised-count original-marker)
    {:original-marker original-marker
     :original-start (tonumber original-start)
     :original-count (tonumber original-count)
     :revised-start (tonumber revised-start)
     :revised-count (tonumber revised-count)}
    nil (case (string.match line "^@@ (%-(%d+),(%d+) %+(%d+),(%d+)) @@")
          (original-marker original-start original-count revised-start revised-count)
          {:original-marker original-marker
           :original-start (tonumber original-start)
           :original-count (tonumber original-count)
           :revised-start (tonumber revised-start)
           :revised-count (tonumber revised-count)}
          nil nil)))

(defcmd0 DiffChunkTrim []
  (let [line (vim.fn.line :.)
        chunk-start (u.find-backwards line chunk-start?)
        {: original-marker : original-start : original-count : revised-start : revised-count } (parse-chunk-header (vim.fn.getline chunk-start))
        lines (without-comments (u.get-lines chunk-start (a.dec line)))
        original-line-count (a.count (a.filter #(not (string.match $1 "^-")) lines))
        revised-line-count (a.count (a.filter #(not (string.match $1 "^-")) lines))
        chunk-line (.. "@@ -" (+ original-start original-line-count) "," (math.max 0 (- original-count original-line-count))
                       " +" (+ revised-start revised-line-count) "," (- revised-count revised-line-count)
                       " @@ (was " original-marker ")")]
    (u.set-lines! (a.dec chunk-start) (a.dec line) [chunk-line])
    (u.set-cursor! (a.inc chunk-start) 0)))
(u.repeatable :diff-chunk-trim ":DiffChunkTrim<CR>")

(defcmd1 DiffChunkMoveTrim [{:args dest}]
  (let [line (vim.fn.line :.)
        file-start (u.find-backwards line file-start?)
        chunk-start (u.find-backwards line chunk-start?)
        {: original-marker : original-start : original-count : revised-start : revised-count } (parse-chunk-header (vim.fn.getline chunk-start))
        lines (u.get-lines chunk-start (a.dec line))
        original-line-count (a.count (a.filter #(not (string.match $1 "^-")) lines))
        revised-line-count (a.count (a.filter #(not (string.match $1 "^-")) lines))
        chunk-line (.. "@@ -" (+ original-start original-line-count) "," (math.max 0 (- original-count original-line-count))
                       " +" (+ revised-start revised-line-count) "," (- revised-count revised-line-count)
                       " @@ (was " original-marker ")")]
    (when (comments? lines)
      (let [header-lines (u.get-lines (a.dec file-start) (u.find-forwards file-start chunk-start?))
            lines (a.concat header-lines lines)]
        (vim.fn.writefile lines dest :a)))
    (u.set-lines! (a.dec chunk-start) (a.dec line) [chunk-line])
    (u.set-cursor! (a.inc chunk-start) 0)))
(u.repeatable :diff-chunk-move-to-commented-trim ":DiffChunkMoveTrim .commented.diff<CR>")

(defcmd0 DiffFileCopy []
  (let [start (u.find-backwards (vim.fn.line :.) file-start?)
        end (u.find-forwards (a.inc start) file-start?)
        lines (u.get-lines (a.dec start) (a.dec end))]
    (vim.fn.setreg "\"" lines :l)))
(u.repeatable :diff-file-copy ":DiffFileCopy<CR>")

(defcmd0 DiffFileDelete []
  (let [start (u.find-backwards (vim.fn.line :.) file-start?)
        end (u.find-forwards (a.inc start) file-start?)
        lines (u.get-lines (a.dec start) (a.dec end))]
    (vim.fn.setreg "" lines :l)
    (u.set-lines! (a.dec start) (a.dec end) [])
    (u.set-cursor! (math.min start (vim.fn.line :$)) 0)))
(u.repeatable :diff-file-delete ":DiffFileDelete<CR>")

(defcmd1 DiffFileMove [{:args dest}]
  (let [start (u.find-backwards (vim.fn.line :.) file-start?)
        end (u.find-forwards (a.inc start) file-start?)
        lines (u.get-lines (a.dec start) (a.dec end))]
    (when (comments? lines)
      (vim.fn.writefile lines dest :a))
    (u.set-lines! (a.dec start) (a.dec end) [])
    (u.set-cursor! (math.min start (vim.fn.line :$)) 0)))
(u.repeatable :diff-file-move-to-commented ":DiffFileMove .commented.diff<CR>")

(defcmd0 DiffFileOpen []
  (let [start (u.find-backwards (vim.fn.line :.) file-start?)
        line (vim.fn.getline start)
        filename (string.match line "^diff %-%-git a/%S+ b/(%S+)$")]
    (nvim.ex.tabnew filename)))
(u.repeatable :diff-file-open ":DiffFileOpen<CR>")

(defcmd0 DiffNoteLine []
  (let [line (vim.fn.line :.)
        content (vim.fn.getline line)]
    (vim.fn.setreg "" [content] :l)
    ; Back up in case we want it after editing something
    (vim.fn.setreg :a [content] :l)
    (u.set-lines! (a.dec line) line ["v" content "^" "" "x"])
    (u.set-cursor! (+ 3 line) 0)
    (u.insert-mode!)))

(defcmd DiffNoteRange {:range true} []
  (let [selected (u.visual-lines)
        [_ start] (vim.fn.getpos "'<")
        [_ end] (vim.fn.getpos "'>")
        lines (a.concat ["v"] selected ["^" "" "x"])]
    (vim.fn.setreg "" selected :l)
    ; Back up in case we want it after editing something
    (vim.fn.setreg :a selected :l)
    (u.set-lines! (a.dec start) end lines)
    (u.set-cursor! (+ 3 end) 0)
    (u.insert-mode!)))

(defcmd0 DiffCopyUrl []
  (let [line (vim.fn.line :.)
        file-start (u.find-backwards line file-start?)
        filename (string.match (vim.fn.getline file-start) "^diff %-%-git a/%S+ b/(%S+)$")
        chunk-start (u.find-backwards line chunk-start?)
        revised-start (string.match (vim.fn.getline chunk-start) "^@@ %-%d+,%d+ %+(%d+),%d+ @@")
        diff-lines (without-comments (u.get-lines (a.dec chunk-start) (a.dec line)))
        revised-line-count (a.count (a.filter #(not (string.match $1 "^-")) diff-lines))
        current-line (+ revised-start revised-line-count)]
    (vim.fn.setreg :* (vim.fn.system (.. "gh browse --no-browser " filename ":" current-line)))))
