(fn defcmd [nm opts args & body]
  `(vim.api.nvim_create_user_command ,(tostring nm) (fn ,nm ,args ,(unpack body)) ,opts))

; Copied from https://github.com/Olical/aniseed/blob/master/lua/aniseed/macros/autocmds.fnl

(fn autocmd [event opt]
  `(vim.api.nvim_create_autocmd
    ,event ,opt))

(fn autocmds [...]
  (var form `(do))
  (each [_ v (ipairs [...])]
    (table.insert form (autocmd (unpack v))))
  (table.insert form 'nil)
  form)

(fn augroup [name ...]
  (var cmds `(do))
  (var group (sym :group))
  (each [_ v (ipairs [...])]
    (let [(event opt) (unpack v)]
      (tset opt :group group)
      (table.insert cmds (autocmd event opt))))
  (table.insert cmds 'nil)
  `(let [,group
         (vim.api.nvim_create_augroup ,name {:clear true})]
     ,cmds
     ,group))

{: autocmd
 : autocmds
 : augroup
 : defcmd}
