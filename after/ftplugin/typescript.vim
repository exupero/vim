let b:ale_linters = ['eslint']

lua require('javascript')
UltiSnipsAddFiletype javascript
let g:ale_javascript_eslint_options = '--rule "no-console: error" --rule "no-unused-vars: error" --rule "no-unused-expressions: error" --rule "@typescript-eslint/no-unused-vars: error"'
