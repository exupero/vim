lua require('diff')

nnoremap <LocalLeader>cd <Plug>(diff-chunk-delete)
nnoremap <LocalLeader>fc <Plug>(diff-file-copy)
nnoremap <LocalLeader>fd <Plug>(diff-file-delete)
nnoremap <LocalLeader>fo <Plug>(diff-file-open)

nnoremap [c :?^@@?<CR>
nnoremap ]c :/^@@/<CR>
nnoremap [d :?^diff?<CR>
nnoremap ]d :/^diff/<CR>
