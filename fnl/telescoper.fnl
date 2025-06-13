(local a (require :aniseed.core))
(local str (require :aniseed.string))
(local nvim (require :aniseed.nvim))
(local actions (require :telescope.actions))
(local action-state (require :telescope.actions.state))
(local conf (require :telescope.config))
(local finders (require :telescope.finders))
(local pickers (require :telescope.pickers))
(local u (require :util))

(fn open-location-keybindings [prompt-bufnr map]
  (actions.select_default:replace
    (fn []
      (actions.close prompt-bufnr)
      (let [selection (action-state.get_selected_entry)]
        (vim.cmd (.. "edit +" selection.value.line " " selection.value.filename)))))
  (map [:i :n] "<TAB>"
    (fn []
      (actions.close prompt-bufnr)
      (let [selection (action-state.get_selected_entry)]
        (vim.cmd (.. "tabnew +" selection.value.line " " selection.value.filename))))))

(fn pick-location [title results entry-maker layout-config]
  (: (pickers.new {}
                  {:prompt_title title
                   :finder (finders.new_table
                             {:results results
                              :entry_maker entry-maker})
                   :sorter (conf.values.generic_sorter {})
                   :previewer (conf.values.qflist_previewer {})
                   :attach_mappings (fn [prompt-bufnr map]
                                      (open-location-keybindings prompt-bufnr map)
                                      true)
                   :layout_config layout-config})
     :find))

(fn ls [title dir]
  (pick-location title
    (u.split-lines (vim.fn.system (.. "ls -at " dir)))
    (fn [entry]
      {:value {:filename (.. dir "/" entry) :line 1}
       :display entry
       :filename (.. dir "/" entry)
       :lnum 1
       :ordinal entry})))

(fn find [title dir args]
  (pick-location title
    (u.split-lines (vim.fn.system (.. "cd " dir " && find * -type f " args)))
    (fn [entry]
      {:value {:filename (.. dir "/" entry) :line 1}
       :display entry
       :filename (.. dir "/" entry)
       :lnum 1
       :ordinal entry})))

(fn system-loc [title cmd]
  (pick-location title
    (vim.json.decode (vim.fn.system cmd))
    (fn [entry]
      {:value {:filename entry.path :line entry.line}
       :display entry.text
       :filename entry.path
       :lnum entry.line
       :ordinal entry.text})))

(fn template [title cmd templater]
  (: (pickers.new {}
                  {:prompt_title title
                   :finder (finders.new_table
                             {:results (u.split-lines (vim.fn.system cmd))
                              :entry_maker (fn [entry]
                                             {:value entry
                                              :display entry
                                              :ordinal entry})})
                   :sorter (conf.values.generic_sorter {})
                   :previewer (conf.values.qflist_previewer {})
                   :attach_mappings (fn [prompt-bufnr map]
                                      (actions.select_default:replace
                                        (fn []
                                          (actions.close prompt-bufnr)
                                          (let [selection (action-state.get_selected_entry)
                                                code (str.trim (vim.fn.system (.. templater " " selection.value)))
                                                [line col] (u.get-cursor)
                                                [cur] (u.get-lines (a.dec line) line)
                                                indent ((cur:gmatch "(%s*)"))
                                                line (a.dec line)]
                                            (u.set-lines! line (a.inc line) (a.map #(.. indent $1) (u.split-lines code)))
                                            (u.set-cursor! (a.inc line) col))))
                                      true)})
     :find))

{: pick-location
 : ls
 : find
 : system-loc
 : template}
