lua require('diff')

setlocal foldmethod=expr
setlocal foldexpr=v:lua.diff_fold_level()
setlocal foldtext=v:lua.diff_fold_text()
setlocal foldlevel=99

nnoremap <LocalLeader>cd <Plug>(diff-chunk-delete)
nnoremap <LocalLeader>fc <Plug>(diff-file-copy)
nnoremap <LocalLeader>fd <Plug>(diff-file-delete)
nnoremap <LocalLeader>fo <Plug>(diff-file-open)

vnoremap <LocalLeader>n :DiffNote<CR>

nnoremap [c :?^@@?<CR>
nnoremap ]c :/^@@/<CR>
nnoremap [d :?^diff?<CR>
nnoremap ]d :/^diff/<CR>

vnoremap [c :?^@@?<CR>
vnoremap ]c :/^@@/-1<CR>
vnoremap [d :?^diff?<CR>
vnoremap ]d :/^diff/-1<CR>
