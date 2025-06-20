(fn async-shell [cmd input]
  (let [buf (vim.api.nvim_create_buf false true)]
    (vim.cmd "vertical new")
    (vim.api.nvim_win_set_buf 0 buf)
    (doto buf
      (vim.api.nvim_buf_set_option :buftype :nofile)
      (vim.api.nvim_buf_set_option :bufhidden :wipe)
      (vim.api.nvim_buf_set_option :filetype :markdown)
      (vim.api.nvim_buf_set_name "LLM output"))
    (let [job-id (vim.fn.jobstart cmd
                   {:stdin :pipe
                    :stdout_buffered false
                    :stderr_buffered false
                    :on_stdout (fn [_ data _]
                                 (when data
                                   (print (vim.inspect data))
                                   (if (= [""] data)
                                     (vim.api.nvim_buf_set_lines buf -1 -1 false [""])
                                     (let [[part & parts] data
                                           line-count (vim.api.nvim_buf_line_count buf)
                                           [last-line] (vim.api.nvim_buf_get_lines buf (a.dec line-count) line-count false)
                                           new-last-line (.. (or last-line "") part)]
                                      (vim.api.nvim_buf_set_lines buf (a.dec line-count) line-count false [new-last-line])
                                      (when (< 0 (length parts))
                                        (vim.api.nvim_buf_set_lines buf -1 -1 false parts))))
                                   (let [win (vim.fn.bufwinid buf)]
                                     (when (not (= -1 win))
                                       (vim.api.nvim_win_set_cursor win [(vim.api.nvim_buf_line_count buf) 0])))))
                    :on_exit (fn [_ exit-code _]
                               (let [exit-message (if (= 0 exit-code)
                                                    "Process completed successfully"
                                                    (.. "Process exited with code " exit-code))]
                                 (vim.api.nvim_buf_set_lines buf -1 -1 false ["" exit-message])))})]
      (if (< 0 job-id)
        (do
          (vim.fn.chansend job-id input)
          (vim.fn.chanclose job-id :stdin))
        (vim.api.nvim_buf_set_lines buf 0 -1 false ["Failed to start command"])))))

{: async-shell}
