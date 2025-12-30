(import-macros {: defcmd0} :macros)

(local a (require :aniseed.core))
(local nvim (require :aniseed.nvim))
(local u (require :util))

(fn divider? [line]
  (string.match line "^============================================================================$"))

(fn filename? [line]
  (string.match line "^File: "))

(fn line? [line]
  (string.match line "^Line: "))

(defcmd0 CoderabbitCommentDelete []
  (let [start (u.find-backwards (vim.fn.line :.) divider?)
        end (u.find-forwards (a.inc start) divider?)
        lines (u.get-lines (a.dec start) (a.dec end))]
    (vim.fn.setreg "" lines :l)
    (u.set-lines! (a.dec start) (a.dec end) [])
    (u.set-cursor! (math.min start (vim.fn.line :$)) 0)))
(u.repeatable :coderabbit-comment-delete ":CoderabbitCommentDelete<CR>")

(defcmd0 CoderabbitCommentOpen []
  (let [line (vim.fn.line :.)
        finder (if (divider? (vim.fn.getline line))
                 u.find-forwards
                 u.find-backwards)
        file-line (finder line filename?)
        filename (string.match (vim.fn.getline file-line) "^File: (%S+)$")
        line-line (finder file-line line?)
        line-start (string.match (vim.fn.getline line-line) "^Line: (%d+)")
        current-line (tonumber line-start)]
    (nvim.ex.tabnew (.. :+ current-line) filename)))
(u.repeatable :coderabbit-comment-open ":CoderabbitCommentOpen<CR>")
