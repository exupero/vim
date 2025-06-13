call plug#begin(stdpath('data').'/plugged')
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'
Plug 'godlygeek/tabular'
Plug 'guns/vim-sexp', { 'for': ['clojure', 'janet', 'fennel', 'hy', 'query'] }
Plug 'tpope/vim-sexp-mappings-for-regular-people', { 'for': ['clojure', 'janet', 'fennel', 'hy', 'query'] }
Plug 'tpope/vim-fugitive'
Plug 'tpope/vim-surround'
Plug 'tpope/vim-repeat'
Plug 'tpope/vim-commentary'
Plug 'tpope/vim-abolish'
Plug 'tpope/vim-unimpaired'
Plug 'tpope/vim-rhubarb'
Plug 'jpalardy/vim-slime'
Plug 'easymotion/vim-easymotion'
Plug 'ConradIrwin/vim-bracketed-paste'
Plug 'udalov/kotlin-vim', { 'for': 'kotlin' }
Plug 'jiangmiao/auto-pairs', { 'tag': 'v2.0.0' }
Plug 'eraserhd/parinfer-rust', { 'for': ['clojure', 'janet', 'fennel', 'hy', 'query'] }
Plug 'Olical/conjure', { 'for': ['clojure', 'janet', 'fennel', 'hy', 'python'], 'branch': 'main' }
Plug 'bakpakin/janet.vim', { 'for': 'janet' }
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
Plug 'gpanders/vim-medieval'
Plug 'github/copilot.vim'

" Fennel-related
Plug 'bakpakin/fennel.vim', { 'for': 'fennel' }
" Plug 'atweiden/vim-fennel'
Plug 'Olical/nfnl'
Plug 'Olical/aniseed'
" Install instructions for these don't include Plug, so I'm not sure what exactly nedes to be done...
" Plug 'udayvir-singh/tangerine.nvim'
" Plug 'udayvir-singh/hibiscus.nvim'
call plug#end()
