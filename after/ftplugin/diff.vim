lua require('diff')

nnoremap <LocalLeader>cf :DiffCopyCurrentFile<CR>
nnoremap <LocalLeader>dc :DiffDeleteCurrentChunk<CR>
nnoremap <LocalLeader>df :DiffDeleteCurrentFile<CR>

nnoremap [c :?^@@?<CR>
nnoremap ]c :/^@@/<CR>
nnoremap [d :?^diff?<CR>
nnoremap ]d :/^diff/<CR>
