(local a (require :aniseed.core))
(local nvim (require :aniseed.nvim))

(fn sort-by-file-and-line [a b]
  (or (< a.filename b.filename)
      (and (= a.filename b.filename)
           (< a.lnum b.lnum))))

(fn show! [title entries sort?]
  (let [entries (a.vals entries)]
    (when sort?
      (table.sort entries sort-by-file-and-line))
    (vim.fn.setqflist [] :r {:title title :items entries})
    (nvim.ex.copen)))

(fn filter! [pred]
  (let [entries (vim.fn.getqflist)]
    (vim.fn.setqflist [] :r {:items (a.filter pred entries)})))

(fn tsquery [capture-name q]
  (let [query (vim.treesitter.parse_query vim.bo.filetype q)
        node (-> (vim.treesitter.get_parser 0)
                 (: :parse)
                 a.first
                 (: :root))
        fname (vim.fn.expand :%)
        unique-entries {}]
    (each [id node metadata (query:iter_captures node 0 0 -1)]
      (when (= capture-name (. query.captures id))
        (let [(start-row start-col) (node:range)]
          (tset unique-entries (.. start-row "." start-col)
                {:filename fname
                 :lnum (a.inc start-row)
                 :col (a.inc start-col)
                 :text (vim.treesitter.get_node_text node 0)}))))
    (a.vals unique-entries)))

(fn parse-locations [stdout]
  (let [entries []]
    (each [fname lnum text (stdout:gmatch "([^:\r\n]+):([0-9]+):([^\r\n]+)")]
      (table.insert entries {:filename fname
                             :module fname
                             :lnum (tonumber lnum)
                             :text text}))
    entries))

(fn rg [q]
  (let [entries []
        str (vim.fn.system (.. "rg -nS \"" (string.gsub q "\"" "\\\"") "\""))]
    (each [fname lnum text (str:gmatch "([^:\r\n]+):([0-9]+):([^\r\n]+)")]
      (table.insert entries {:filename fname
                             :module fname
                             :lnum (tonumber lnum)
                             :col (string.find text q)
                             :text text}))
    entries))

{: show!
 : filter!
 : tsquery
 : parse-locations
 : rg}
