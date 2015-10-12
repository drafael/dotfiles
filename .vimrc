set nocompatible               " choose no compatibility with legacy vi

filetype on                    " work around stupid osx bug
filetype off                   " required

set encoding=utf-8             " open file with encoding
set fileencoding=utf-8         " save file with encoding
set fileformats=unix,dos,mac   " use Unix as the standard file type
set nobackup                   " do not keep backup files
set noswapfile                 " do not write intermediate swap files
set nowrap                     " don't wrap lines
set number                     " display line numbers on the left
set cursorline                 " highlight current line
set autoread                   " when a file is changed from the outside
set lazyredraw                 " don't redraw while executing macros
set history=1000               " how many lines of history VIM has to remember
set title                      " change the terminal's title
set noerrorbells               " don't beep
set visualbell                 " don't beep
set t_vb=                      "   and don't flash the screen either
set ruler                      " always show current position
set mouse=a                    " enable using the mouse if terminal emulator supports it
set mousehide                  " hide the mouse cursor while typing
set virtualedit=all            " moving beyond the end of a line
set showcmd                    " display incomplete commands
set laststatus=2               " show status line
set noshowmode                 " hide mode line (airline.vim takes care of us)
set splitbelow                 " splitting a window will put the new window below the current one
set splitright                 " splitting a window will put the new window right of the current one
set scrolloff=3                " lines to keep visible before and after cursor
set sidescrolloff=7            " columns to keep visible before and after cursor
set sidescroll=1               " continuous horizontal scroll rather than jumpy
set showmatch                  " show matching brackets when text indicator is over them
set matchtime=2                " tens of a second to show matching parentheses
set hlsearch                   " highlight matches
set incsearch                  " incremental searching
set ignorecase                 " searches are case insensitive
set smartcase                  "   unless they contain at least one capital letter
set gdefault                   " global search by default :%s/pattern/replacement/g
set wildmenu                   " make tab completion for files/buffers act like bash
set wildmode=list:full         " show a list when pressing <Tab> and complete first full match

set wildignore+=.DS_Store
set wildignore+=*/target/*
set wildignore+=,*.swp,*~,*.zip,*.pyc,*.class,*.jar,*.so,*.dll,*.exe

"
" http://erikzaadi.com/2012/03/19/auto-installing-vundle-from-your-vimrc/
"
let readme=expand('~/.vim/bundle/vundle/README.md')
if !filereadable(readme)
  echo "======================================================"
  echo "    Installing Vundle (vim plugin manager)..."
  echo "======================================================"
  echo ""
  silent !mkdir -p ~/.vim/bundle
  silent !git clone https://github.com/gmarik/vundle.git ~/.vim/bundle/vundle
  let s:install_plugins=1
else
  let s:install_plugins=0
endif

set rtp+=~/.vim/bundle/vundle/

call vundle#begin()            " start plugin listing

Plugin 'gmarik/vundle'
Plugin 'tpope/vim-endwise'
Plugin 'jiangmiao/auto-pairs'
Plugin 'tmhedberg/matchit'
Plugin 'ervandew/supertab'
Plugin 'tomtom/tcomment_vim'
Plugin 'bling/vim-airline'
Plugin 'kien/ctrlp.vim'
Plugin 'regedarek/ZoomWin'
Plugin 'sickill/vim-pasta'
Plugin 'scrooloose/nerdtree'

" syntax and filetype
Plugin 'derekwyatt/vim-scala'
Plugin 'fatih/vim-go'
Plugin 'motus/pig.vim'
Plugin 'rverk/snipmate-pig'

" command-line tools integration
Plugin 'tpope/vim-fugitive'
Plugin 'mileszs/ack.vim'
Plugin 'rking/ag.vim'
Plugin 'majutsushi/tagbar'
Plugin 'scrooloose/syntastic'

" TextMate like snippets
Plugin 'tomtom/tlib_vim'
Plugin 'MarcWeber/vim-addon-mw-utils'
Plugin 'garbas/vim-snipmate'
Plugin 'honza/vim-snippets'

" color schemes (here's the gallery/screenshots http://vimcolors.com)
Plugin 'altercation/vim-colors-solarized'   " http://ethanschoonover.com/solarized
Plugin 'vim-scripts/xoria256.vim'           " http://vimcolors.com/262/xoria256/dark
Plugin 'nanotech/jellybeans.vim'            " http://vimcolors.com/1/jellybeans/dark
Plugin 'cocopon/iceberg.vim'                " http://cocopon.me/app/vim-iceberg/
Plugin 'stulzer/heroku-colorscheme'         " http://vimcolors.com/201/heroku/dark
Plugin 'uu59/vim-herokudoc-theme'           " http://vimcolors.com/95/herokudoc-gvim/dark
Plugin 'sickill/vim-sunburst'               " http://vimcolors.com/177/Sunburst/dark
Plugin '29decibel/codeschool-vim-theme'     " http://vimcolors.com/33/codeschool/dark
Plugin 'cseelus/vim-colors-clearance'       " http://vimcolors.com/147/clearance/dark
Plugin 'fatih/molokai'                      " http://vimcolors.com/168/molokai/dark
Plugin 'znake/znake-vim'                    " http://vimcolors.com/240/znake/dark
Plugin 'croaker/mustang-vim'                " http://vimcolors.com/248/mustang/dark
Plugin 'fent/vim-frozen'                    " http://vimcolors.com/272/frozen/dark
Plugin 'MPiccinato/wombat256'               " http://vimcolors.com/278/wombat256/dark

call vundle#end()              " end of plugin listing

if s:install_plugins == 1
  :PluginInstall
endif

filetype plugin indent on      " enable file type detection, plugins and indentation
syntax enable                  " enable syntax highlighting

"
"  Whitespace settings
"
set tabstop=4                  " spaces per tab
set softtabstop=4              " when hitting <BS>, pretend like a tab is removed, even if spaces
set shiftwidth=4               " number of spaces to use for autoindenting
set shiftround                 " use multiple of shiftwidth when indenting with '<' and '>'
set expandtab                  " spaces instead of tabs
set smarttab                   " use shiftwidth to enter tabs
set autoindent                 " automatically indent to match adjacent lines
set smartindent
set nolist                     " hide whitespace characters
set listchars=tab:▸\ ,trail:•,eol:¬  " how to show 'invisible' characters
set linebreak
let &showbreak='↪ '            " string to put at the start of lines that have been wrapped
set backspace=indent,eol,start " configure backspace so it acts as it should act

augroup syntax_settings
  autocmd!
  autocmd BufRead,BufNewFile *.gradle setlocal filetype=groovy syntax=groovy
  autocmd BufRead,BufNewFile *.pig setlocal filetype=pig syntax=pig
  autocmd BufRead,BufNewFile Vagrantfile,Rakefile,Capfile,Gemfile setlocal filetype=ruby syntax=ruby
  autocmd FileType ruby,haml,eruby,yaml,html,sass,cucumber,vim setlocal tabstop=2 shiftwidth=2 softtabstop=2 expandtab
augroup END

"
"  OS clipboard integration
"
"  when possible use + register for copy-paste
"  on Mac and Windows, use * register for copy-paste
"
if has('clipboard')
  if has('unnamedplus')
    set clipboard=unnamed,unnamedplus
  else
    set clipboard=unnamed
  endif
endif

"
" Status line
"
if !exists('g:airline_symbols')
  let g:airline_symbols = {}
endif

let g:airline_left_sep = ''
let g:airline_left_alt_sep = ''
let g:airline_right_sep = ''
let g:airline_right_alt_sep = ''
let g:airline_symbols.readonly = '[RO]'

if has('macunix') || system('uname')=~'Darwin'
  let g:airline_symbols.linenr = '␤'
  " let g:airline_symbols.linenr = '¶'
  " let g:airline_symbols.linenr = '␊'
  let g:airline_symbols.branch = '⎇'
  " let g:airline_symbols.whitespace = 'Ξ'
  " let g:airline_symbols.paste = 'ρ'
else
  let g:airline_symbols.linenr = 'LN'
  let g:airline_symbols.branch = 'BR'
endif

"
"  GUI/Terminal specific settings
"
if has("gui_running")          " GUI is running or is about to start
  set guioptions-=m            " remove menu bar
  set guioptions-=T            " remove toolbar
  set guioptions-=l            " remove left scrollbar
  set guioptions-=L            "   when there is a vertically split window
  set guioptions-=r            " remove right scrollbar
  set guioptions-=R            "   when there is a vertically split window
  set lines=48 columns=160     " maximize gvim window
  " set guifont=Menlo:h14        " favorite GUI font
  set guifont=Monaco:h14       " favorite GUI font
  set background=light
  colorscheme solarized        " GUI color scheme
else                           " this is console Vim
  set t_Co=256                 " 256 colors
  set background=dark
  colorscheme jellybeans       " terminal color scheme
  if exists("+lines")
    set lines=46
  endif
  if exists("+columns")
    set columns=160
  endif
endif

"
" File/source code navigation
"
map <F2> :NERDTreeToggle<CR>
let g:NERDTreeShowHidden=1

map <F8> :TagbarToggle<CR>

"
" Full path fuzzy file finder
"
let g:ctrlp_map = '<c-p>'              " default mapping
let g:ctrlp_cmd = 'CtrlP'              " default command
let g:ctrlp_working_path_mode = 'ra'   " set local working directory
let g:ctrlp_show_hidden = 1

"
"  Mappings
"
let mapleader=','

nnoremap // :TComment<CR>
vnoremap // :TComment<CR>

" when indenting with < and >, make it easy to repeat
vnoremap < <gv
vnoremap > >gv

" Ctrl+S to save the current file
nnoremap <c-s> :w<CR>
inoremap <c-s> <Esc>:w<CR>

" EOF
