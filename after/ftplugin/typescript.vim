let b:ale_linters = ['eslint']

lua require('javascript')
UltiSnipsAddFiletype javascript
let g:ale_javascript_eslint_options = '--rule "no-console: error" --rule "no-unused-vars: error" --rule "no-unused-expressions: error" --rule "@typescript-eslint/no-unused-vars: error"'

nnoremap <Plug>(insert-before) :call JavascriptInsertBefore()<CR>
nnoremap <Plug>(insert-after) :call JavascriptInsertAfter()<CR>
nnoremap <Plug>(log-word-before-cursor) :JavascriptLogWordBeforeCursor<CR>
nnoremap <Plug>(log-word-before-mark) :JavascriptLogWordBeforeMark u<CR>
nnoremap <Plug>(log-word-after-cursor) :JavascriptLogWordAfterCursor<CR>

vnoremap <Plug>(log-selection-before-cursor) :JavascriptLogSelectionBeforeCursor<CR>
vnoremap <Plug>(log-selection-before-mark) :JavascriptLogSelectionBeforeMark u<CR>
vnoremap <Plug>(leg-selection-after-cursor) :JavascriptLogSelectionAfterCursor<CR>
