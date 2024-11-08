call plug#begin(stdpath('data').'/plugged')
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'
Plug 'godlygeek/tabular'
Plug 'tpope/vim-fugitive'
Plug 'tpope/vim-surround'
Plug 'tpope/vim-repeat'
Plug 'tpope/vim-commentary'
Plug 'tpope/vim-abolish'
Plug 'tpope/vim-sexp-mappings-for-regular-people', { 'for': ['clojure', 'janet', 'fennel', 'hy'] }
Plug 'tpope/vim-unimpaired'
Plug 'tpope/vim-rhubarb'
Plug 'jpalardy/vim-slime'
Plug 'easymotion/vim-easymotion'
Plug 'ConradIrwin/vim-bracketed-paste'
Plug 'udalov/kotlin-vim', { 'for': 'kotlin' }
Plug 'jiangmiao/auto-pairs', { 'tag': 'v2.0.0' }
Plug 'guns/vim-sexp'
Plug 'eraserhd/parinfer-rust', { 'for': ['clojure', 'janet', 'fennel', 'hy'] }
Plug 'Olical/conjure', { 'for': ['clojure', 'janet', 'fennel', 'hy', 'python'], 'tag': 'v4.52.0' }
Plug 'bakpakin/janet.vim', { 'for': 'janet' }
"Plug 'bakpakin/fennel.vim', { 'for': 'fennel' }
Plug 'Olical/aniseed'
Plug 'Olical/nvim-local-fennel', { 'tag': 'v2.19.0' }
Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}
Plug 'nvim-treesitter/nvim-treesitter-refactor'
Plug 'nvim-treesitter/nvim-treesitter-textobjects'
Plug 'ludovicchabant/vim-gutentags'
Plug 'alvan/vim-closetag'
Plug 'hylang/vim-hy', { 'for': ['hy'] }
Plug 'preservim/vim-markdown'
Plug 'inkarkat/vim-SyntaxRange'
Plug 'mcchrish/fountain.vim'
Plug 'ahayworth/ink-syntax-vim'
Plug 'pangloss/vim-javascript'
Plug 'leafgarland/typescript-vim'
Plug 'MaxMEllon/vim-jsx-pretty'
Plug 'peitalin/vim-jsx-typescript'
Plug 'SirVer/ultisnips'
Plug 'fcharlier/openssl.vim'
Plug 'nvim-lua/plenary.nvim'
Plug 'nvim-telescope/telescope.nvim', { 'tag': '0.1.3' }
Plug 'neovim/nvim-lspconfig'
Plug 'dense-analysis/ale'
Plug 'neoclide/coc.nvim', {'branch': 'release'}
Plug 'jparise/vim-graphql'
Plug 'subnut/nvim-ghost.nvim'
Plug 'Olical/nfnl'
Plug 'gpanders/vim-medieval'
call plug#end()
