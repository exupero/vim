set nonumber
set colorcolumn=0
setlocal foldmethod=indent

lua require('python')

nnoremap <Plug>(insert-before) :call PythonInsertBefore()<CR>
nnoremap <Plug>(insert-after) :call PythonInsertAfter()<CR>
nnoremap <Plug>(log-word-before-cursor) :PythonLogWordBeforeCursor<CR>
nnoremap <Plug>(log-word-before-mark) :PythonLogWordBeforeMark u<CR>
nnoremap <Plug>(log-word-after-cursor) :PythonLogWordAfterCursor<CR>

vnoremap <Plug>(log-selection-before-cursor) :PythonLogSelectionBeforeCursor<CR>
vnoremap <Plug>(log-selection-before-mark) :PythonLogSelectionBeforeMark u<CR>
vnoremap <Plug>(leg-selection-after-cursor) :PythonLogSelectionAfterCursor<CR>
