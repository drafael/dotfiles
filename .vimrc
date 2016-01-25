set nocompatible               " choose no compatibility with legacy vi

filetype on                    " work around stupid osx bug
filetype off                   " required

set encoding=utf-8             " open file with encoding
set fileencoding=utf-8         " save file with encoding
set fileformats=unix,dos,mac   " use Unix as the standard file type
set nobackup                   " do not keep backup files
set noswapfile                 " do not write intermediate swap files
set nowrap                     " don't wrap lines
set colorcolumn=120            " show the line to wrap the long line by myself
set number                     " display line numbers on the left
set cursorline                 " highlight current line
set guicursor=n:blinkon0       " turn off the blinking cursor in normal mode
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

set wildignore+=.DS_Store,Thumbs.db
set wildignore+=.git/*,.hg/*,.svn/*,.vagrant/*
set wildignore+=.idea/*,*.iml,*.eml,*.ipr
set wildignore+=.project,.classpath,.settings/*
set wildignore+=*.class,*.jar,*.war,*.ear
set wildignore+=target/*,classes/*,out/*,dist/*
set wildignore+=node_modules/*,bower_components/*
set wildignore+=*.pyc,*.o,*.obj
set wildignore+=*.bak,*.swp,*~,*.zip,*.tgz,*.gz,*.pdf,*.so,*.dll,*.exe
set wildignore+=*.jpg,*.jpeg,*.png,*.gif,*.ico,*.mp3,*.mp4,*.m4v,*.m4a

"
" http://erikzaadi.com/2012/03/19/auto-installing-vundle-from-your-vimrc/
"
let readme=expand('~/.vim/bundle/Vundle.vim/README.md')
if !filereadable(readme)
  echo "======================================================"
  echo "    Installing Vundle (vim plugin manager)..."
  echo "======================================================"
  echo ""
  silent !mkdir -p ~/.vim/bundle
  silent !git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim
  let s:install_plugins=1
else
  let s:install_plugins=0
endif

set rtp+=~/.vim/bundle/Vundle.vim/ " set the runtime path to include Vundle and initialize
call vundle#begin()                " start plugin listing
Plugin 'VundleVim/Vundle.vim'      " let Vundle manage Vundle, required

Plugin 'tpope/vim-endwise'
Plugin 'tpope/vim-surround'
Plugin 'tpope/vim-repeat'
Plugin 'tpope/vim-vinegar'
Plugin 'jiangmiao/auto-pairs'
Plugin 'tmhedberg/matchit'
Plugin 'ervandew/supertab'
Plugin 'tomtom/tcomment_vim'
Plugin 'bling/vim-airline'
Plugin 'ctrlpvim/ctrlp.vim'
Plugin 'regedarek/ZoomWin'
Plugin 'sickill/vim-pasta'
Plugin 'airblade/vim-rooter'

" TextMate like snippets
Plugin 'tomtom/tlib_vim'
Plugin 'MarcWeber/vim-addon-mw-utils'
Plugin 'garbas/vim-snipmate'
Plugin 'honza/vim-snippets'

" syntax and filetype
Plugin 'fatih/vim-go'
Plugin 'motus/pig.vim'
Plugin 'rverk/snipmate-pig'
Plugin 'derekwyatt/vim-scala'
Plugin 'ekalinin/Dockerfile.vim'
Plugin 'burnettk/vim-angular'
Plugin 'matthewsimo/angular-vim-snippets'
Plugin 'bonsaiben/bootstrap-snippets'
Plugin 'tmux-plugins/vim-tmux'

" command-line tools integration
Plugin 'tpope/vim-fugitive'
Plugin 'mileszs/ack.vim'
Plugin 'rking/ag.vim'
Plugin 'majutsushi/tagbar'
Plugin 'scrooloose/syntastic'

" color schemes (here's the gallery/screenshots http://vimcolors.com)
Plugin 'altercation/vim-colors-solarized'   " http://ethanschoonover.com/solarized
Plugin 'nanotech/jellybeans.vim'            " http://vimcolors.com/1/jellybeans/dark
Plugin 'cocopon/iceberg.vim'                " http://cocopon.me/app/vim-iceberg/
Plugin 'stulzer/heroku-colorscheme'         " http://vimcolors.com/201/heroku/dark
Plugin '29decibel/codeschool-vim-theme'     " http://vimcolors.com/33/codeschool/dark


call vundle#end()              " end of plugin listing
if s:install_plugins == 1      " auto installing plugins
  :PluginInstall
endif

filetype plugin indent on      " enable file type detection, plugins and indentation
syntax enable                  " enable syntax highlighting

"
"  Default whitespace settings
"
set tabstop=4                        " spaces per tab
set softtabstop=4                    " when hitting <BS>, pretend like a tab is removed, even if spaces
set shiftwidth=4                     " number of spaces to use for autoindenting
set shiftround                       " use multiple of shiftwidth when indenting with '<' and '>'
set expandtab                        " spaces instead of tabs
set smarttab                         " use shiftwidth to enter tabs
set autoindent                       " automatically indent to match adjacent lines
set smartindent
set nolist                           " hide whitespace characters
set listchars=tab:▸\ ,trail:•,eol:¬  " how to show 'invisible' characters
set linebreak
let &showbreak='↪ '                  " string to put at the start of lines that have been wrapped
set backspace=indent,eol,start       " configure backspace so it acts as it should act

augroup vimrcEx
  autocmd!
  " Changes Vim working directory to project root
  autocmd BufEnter * :Rooter

  " Override file type
  autocmd BufRead,BufNewFile *.gradle setlocal filetype=groovy syntax=groovy
  autocmd BufRead,BufNewFile *.pig setlocal filetype=pig syntax=pig
  autocmd BufRead,BufNewFile *.html.erb setlocal filetype=html
  autocmd BufRead,BufNewFile Vagrantfile,Rakefile,Capfile,Gemfile,Brewfile,Caskfile setlocal filetype=ruby syntax=ruby

  " Override whitespace settings
  autocmd FileType ruby,haml,eruby,yaml,html,sass,cucumber,vim set tabstop=2 shiftwidth=2 softtabstop=2 expandtab
augroup END

"
" Autocomplete (Insert mode CTRL+N/CTRL+P)
"
set dictionary+=~/.vim/bundle/bootstrap-snippets/dictionary
set complete+=k
let g:SuperTabDefaultCompletionType = "context"
let g:SuperTabContextDefaultCompletionType = '<C-n>'    " navigate the completion menu from top to bottom

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
  let g:airline_symbols.branch = '⎇'
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
  set guifont=Monaco:h14
  set background=light
  colorscheme solarized        " GUI color scheme
else                           " this is console Vim
  set t_Co=256                 " 256 colors
  set background=dark
  colorscheme solarized        " terminal color scheme
endif

"
"  Mappings
"
let mapleader = " "

" Quickly edit/reload the vimrc file
nmap <silent> <leader>ev :e $MYVIMRC<CR>
nmap <silent> <leader>sv :so $MYVIMRC<CR>

map <leader>w :bd<CR>

call togglebg#map("<F5>")              " Solarized color scheme: toggle background

nnoremap // :TComment<CR>
vnoremap // :TComment<CR>

" when indenting with < and >, make it easy to repeat
vnoremap < <gv
vnoremap > >gv

" typical selection
nnoremap <S-Down> vgj
nnoremap <S-Up> vgk
nnoremap <S-Left> vh
nnoremap <S-Right> vl
vnoremap <S-Down> gj
vnoremap <S-Up> gk
inoremap <S-Up> <C-o>vgk
inoremap <S-Down> <C-o>vgj
inoremap <S-Left> <C-o>h<C-o>v
inoremap <S-Right> <C-o>v

" IDE like autocompletion
imap <C-Space> <Plug>snipMateTrigger

"
" Full path fuzzy file finder
"
let g:ctrlp_map = '<C-p>'               " default mapping
let g:ctrlp_cmd = 'CtrlP'               " default command
let g:ctrlp_working_path_mode = 'ra'    " set local working directory
let g:ctrlp_root_markers = ['pom.xml', 'build.xml']
let g:ctrlp_show_hidden = 1
let g:ctrlp_by_filename = 1             " searching by filename (as opposed to full path)
let g:ctrlp_match_window_reversed = 0   " show the results from top to bottom
let g:ctrlp_match_window = 'bottom,order:ttb,min:1,max:15,results:15'
let g:ctrlp_custom_ignore = {
      \ 'dir':  '\v[\/](\.(git|idea|hg|svn|vagrant|settings))|(target|classes|dist|bower_components|node_modules)$',
      \ 'file': '\v\.(iml|eml|ipr|project|classpath|class|jar|war|ear|zip|jpeg|jpg|png|gif|exe|so|dll|pdf)$',
      \ }

map <leader>t :CtrlP<CR>
map <leader>e :CtrlPMRU<CR>
map <leader>b :CtrlPBuffer<CR>

" Copy & paste to system clipboard with <Space>p and <Space>y
vmap <Leader>y "+y
vmap <Leader>d "+d
nmap <Leader>p "+p
nmap <Leader>P "+P
vmap <Leader>p "+p
vmap <Leader>P "+P

" File/source code navigation
map <F8> :TagbarToggle<CR>

" ignore angular directive lint errors with Vim and syntastic
let g:syntastic_html_tidy_ignore_errors=['proprietary attribute "ng-']

" For (sort of) modern standards in :TOhtml output
let g:html_use_css   = 1
let g:html_use_xhtml = 0

"  Change Vim cursor shape in different modes
if exists('$TMUX')
  let &t_SI = "\<Esc>Ptmux;\<Esc>\e[5 q\<Esc>\\"
  let &t_EI = "\<Esc>Ptmux;\<Esc>\e[2 q\<Esc>\\"
elseif exists('$TERM_PROGRAM') && $TERM_PROGRAM =~ "iTerm.app"
  let &t_SI = "\e[5 q"
  let &t_EI = "\e[2 q"
endif

" EOF
