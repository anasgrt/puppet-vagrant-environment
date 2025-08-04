" ============================================================================
" Minimal Puppet-Optimized Vim Configuration
" ============================================================================

" Basic Settings
" ============================================================================
set nocompatible               " Disable vi compatibility
filetype off                   " Required for plugin loading

" Plugin Management (vim-plug) - Just for Puppet syntax
" ============================================================================
if empty(glob('~/.vim/autoload/plug.vim'))
  silent !curl -fLo ~/.vim/autoload/plug.vim --create-dirs
    \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

call plug#begin('~/.vim/plugged')
Plug 'rodjek/vim-puppet'      " Essential for Puppet syntax highlighting
call plug#end()

syntax enable                  " Enable syntax highlighting
filetype plugin indent on     " Enable filetype detection and indentation

" Display Settings
set cursorline                 " Highlight current line
set showcmd                    " Show command in status line
set laststatus=2              " Always show status line
set ruler                     " Show cursor position

" Search Settings
set incsearch                 " Search as you type
set hlsearch                  " Highlight search results
set ignorecase                " Case insensitive search
set smartcase                 " Case sensitive when uppercase used

" Indentation (Puppet Standard: 2 spaces)
set expandtab                 " Use spaces instead of tabs
set tabstop=2                 " Tab width
set shiftwidth=2              " Indent width
set softtabstop=2             " Soft tab width
set autoindent                " Auto-indent new lines

" File Handling
set autoread                  " Auto reload changed files
set hidden                    " Allow switching buffers without saving
set encoding=utf-8            " UTF-8 encoding

" No Backup Files
set nobackup
set nowritebackup
set noswapfile

" Puppet-Specific Configuration
" ============================================================================
augroup puppet_config
    autocmd!
    " Detect Puppet files
    autocmd BufRead,BufNewFile *.pp set filetype=puppet
    autocmd BufRead,BufNewFile Puppetfile set filetype=ruby
    autocmd BufRead,BufNewFile Vagrantfile set filetype=ruby

    " Puppet file settings
    autocmd FileType puppet setlocal expandtab tabstop=2 shiftwidth=2 softtabstop=2
    autocmd FileType puppet setlocal commentstring=#\ %s
augroup END

" YAML Configuration (for Hiera)
augroup yaml_config
    autocmd!
    autocmd FileType yaml setlocal expandtab tabstop=2 shiftwidth=2 softtabstop=2
augroup END

" Key Mappings
" ============================================================================
let mapleader = ","

" Quick save and quit
nnoremap <leader>w :w<CR>
nnoremap <leader>q :q<CR>

" Clear search highlights
nnoremap <leader><space> :nohlsearch<CR>

" Puppet validation shortcuts
nnoremap <leader>pv :!puppet parser validate %<CR>
nnoremap <leader>pl :!puppet-lint %<CR>

" Simple split navigation
nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l

" Color Scheme
" ============================================================================
colorscheme desert           " Simple built-in color scheme

" Status Line
" ============================================================================
set statusline=%f            " Filename
set statusline+=\ %m         " Modified flag
set statusline+=\ %y         " Filetype
set statusline+=%=           " Right align
set statusline+=\ %l/%L      " Line/total lines
set statusline+=\ %c         " Column number

" Productivity
" ============================================================================
" Remove trailing whitespace on save
autocmd BufWritePre * :%s/\s\+$//e

" Return to last edit position
autocmd BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g'\"" | endif
