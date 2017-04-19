set nocompatible               " choose no compatibility with legacy vi

filetype on                    " work around stupid osx bug
filetype off                   " required

scriptencoding utf-8
set encoding=utf-8             " open file with encoding
set fileencoding=utf-8         " save file with encoding
set fileformats=unix,dos,mac   " use Unix as the standard file type
set nobackup                   " do not keep backup files
set noswapfile                 " do not write intermediate swap files
set nowrap                     " don't wrap lines
set colorcolumn=120            " show the line to wrap the long line by myself
set number                     " display line numbers on the left
set cursorline                 " highlight current line
" set cursorcolumn               " highlight current column
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
set shortmess=a                " disable annoying messages "Press Enter or type command to continue"
set hidden
set autochdir                  " change the current working directory whenever you open a file, switch buffers, delete a buffer or open/close a window

set wildignore+=.DS_Store,._*,Thumbs.db
set wildignore+=.git/*,.hg/*,.svn/*,.vagrant/*,.gradle/*
set wildignore+=.idea/*,*.iml,*.eml,*.ipr,*.iws
set wildignore+=.project,.classpath,.settings/*
set wildignore+=*.class,*.jar,*.war,*.ear
set wildignore+=target/*,classes/*,build/*,out/*,dist/*
set wildignore+=*.min.js,node_modules/*,bower_components/*,.sass-cache/*
set wildignore+=*.pyc,*.pyo,*.o,*.a,*.obj
set wildignore+=*.bak,*.swp,*~,*.zip,*.tgz,*.gz,*.pdf,*.dylib,*.so,*.dll,*.exe
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

set rtp+=~/.vim/bundle/Vundle.vim/          " set the runtime path to include Vundle and initialize
call vundle#begin()                         " start plugin listing
Plugin 'VundleVim/Vundle.vim'               " let Vundle manage Vundle (required)

Plugin 'tpope/vim-endwise'                  " wisely add 'end' in ruby, endfunction/endif/more in vim script, etc
Plugin 'tpope/vim-surround'                 " quoting/parenthesizing made simple
Plugin 'tpope/vim-repeat'                   " enable repeating supported plugin maps with '.'
Plugin 'tpope/vim-vinegar'                  " enhances netrw (built in directory browser)
Plugin 'jiangmiao/auto-pairs'               " Insert or delete brackets, parens, quotes in pair
Plugin 'tmhedberg/matchit'                  " extended % matching for HTML and many other languages
Plugin 'ervandew/supertab'                  " Perform all insert mode completions with Tab
Plugin 'tomtom/tcomment_vim'                " provides easy to use, file-type sensible comments
Plugin 'bling/vim-airline'                  " Status line
Plugin 'vim-airline/vim-airline-themes'     " A collection of themes for vim-airline
Plugin 'ctrlpvim/ctrlp.vim'                 " Full path fuzzy file, buffer, mru, tag, ... finder for Vim
Plugin 'vim-ctrlspace/vim-ctrlspace'
Plugin 'sickill/vim-pasta'                  " Pasting in Vim with indentation adjusted to destination context
Plugin 'airblade/vim-rooter'                " Changes Vim working directory to project root
Plugin 'ntpeters/vim-better-whitespace'     " Strip trailing whitespace
Plugin 'Yggdroot/indentLine'                " display the indention levels with thin vertical lines
Plugin 'editorconfig/editorconfig-vim'      " EditorConfig plugin for Vim http://editorconfig.org
Plugin 'xolox/vim-session'                  " Extended session management for Vim (:mksession on steroids)
Plugin 'xolox/vim-misc'                     "   the vim-session plug-in requires the vim-misc plug-in

" TextMate like snippets
Plugin 'tomtom/tlib_vim'                    " Some utility functions for VIM (required)
Plugin 'MarcWeber/vim-addon-mw-utils'       " interpret a file by function and cache file automatically (required)
Plugin 'garbas/vim-snipmate'                " implements some of TextMate's snippets features in Vim
Plugin 'honza/vim-snippets'                 " vim-snipmate default snippets (Previously snipmate-snippets)

" syntax and filetype
Plugin 'sheerun/vim-polyglot'               " A solid language pack for Vim
Plugin 'gisphm/vim-gitignore'               " Gitignore plugin for Vim
Plugin 'fatih/vim-go'                       " Go development plugin for Vim
Plugin 'Glench/Vim-Jinja2-Syntax'           " An up-to-date jinja2 syntax file
Plugin 'vim-scripts/Vim-R-plugin'
Plugin 'motus/pig.vim'                      " Pig syntax highlighting
Plugin 'rverk/snipmate-pig'                 " PigLating snippets for snipmate
Plugin 'autowitch/hive.vim'                 " Syntax highlighting for Hive
Plugin 'burnettk/vim-angular'               " AngularJS with Vim
Plugin 'matthewsimo/angular-vim-snippets'
Plugin 'bonsaiben/bootstrap-snippets'       " Bootstrap 3.2 markup snippets for vim-snipmate

" command-line tools integration
Plugin 'tpope/vim-fugitive'                 " Git wrapper so awesome, it should be illegal
Plugin 'mileszs/ack.vim'                    " Vim frontend for the Perl module App::Ack
Plugin 'rking/ag.vim'                       " Vim frontend for the Ag, aka the_silver_searcher
Plugin 'majutsushi/tagbar'                  " plugin that displays tags in a window, ordered by scope
Plugin 'scrooloose/syntastic'               " Syntax checking hacks for vim
Plugin 'lambdalisue/vim-gita'               " An awesome git handling plugin

" color schemes
Plugin 'altercation/vim-colors-solarized'   " http://ethanschoonover.com/solarized
Plugin 'nanotech/jellybeans.vim'            " http://vimcolors.com/1/jellybeans/dark
Plugin 'cocopon/iceberg.vim'                " http://cocopon.me/app/vim-iceberg/
Plugin 'stulzer/heroku-colorscheme'         " http://vimcolors.com/201/heroku/dark
Plugin '29decibel/codeschool-vim-theme'     " http://vimcolors.com/33/codeschool/dark
Plugin 'nlknguyen/papercolor-theme'         " Inspired by Google's Material Design

call vundle#end()                           " end of plugin listing
if s:install_plugins == 1                   " auto installing plugins
  :PluginInstall
endif

"
"  Syntax & FileType
"
filetype plugin indent on                   " enable file type detection, plugins and indentation
syntax enable                               " enable syntax highlighting

augroup OverrideFileType
  autocmd!
  autocmd BufRead,BufNewFile Vagrantfile setlocal filetype=ruby
  autocmd BufRead,BufNewFile playbook.yml,site.yml,setup.yml,main.yml setlocal filetype=ansible
  autocmd BufRead,BufNewFile */tasks/*.yml,*/roles/*.yml,*/handlers/*.yml setlocal filetype=ansible
  autocmd BufRead,BufNewFile */vars/*,*/host_vars/*,*/group_vars/* setlocal filetype=ansible
  autocmd BufRead,BufNewFile Rakefile,Capfile,Gemfile setlocal filetype=ruby
  autocmd BufRead,BufNewFile *.html.erb setlocal filetype=html
  autocmd BufRead,BufNewFile *.gradle setlocal filetype=groovy
  autocmd BufRead,BufNewFile *.pig setlocal filetype=pig
  autocmd BufRead,BufNewFile *.hql setlocal filetype=hive
  autocmd BufRead,BufNewFile *.q setlocal filetype=hive
augroup END

" in order to get full support for Golng I use vim-go plugin directly
let g:polyglot_disabled = ['go']

" By default syntax-highlighting for Functions, Methods and Structs is disabled
let g:go_highlight_functions = 1
let g:go_highlight_methods = 1
let g:go_highlight_fields = 1
let g:go_highlight_types = 1
let g:go_highlight_operators = 1
let g:go_highlight_build_constraints = 1

" Sometimes when using both vim-go and syntastic Vim will start lagging while saving and opening files. The following fixes this:
let g:syntastic_go_checkers = ['golint', 'govet', 'errcheck']
let g:syntastic_mode_map = { 'mode': 'active', 'passive_filetypes': ['go'] }

" ignore angular directive lint errors with Vim and syntastic
let g:syntastic_html_tidy_ignore_errors = ['proprietary attribute "ng-']
let g:syntastic_disabled_filetypes = ['html']

"
"  Default Whitespace
"
set tabstop=4                               " (ts) width (in spaces) that a <tab> is displayed as
set softtabstop=4                           " when hitting <BS>, pretend like a tab is removed, even if spaces
set shiftwidth=4                            " (sw) width (in spaces) used in each step of autoindent (aswell as << and >>)
set shiftround                              " use multiple of shiftwidth when indenting with '<' and '>'
set expandtab                               " (et) expand tabs to spaces (use :retab to redo entire file)
set smarttab                                " use shiftwidth to enter tabs
set autoindent                              " automatically indent to match adjacent lines
set smartindent
set nolist                                  " hide whitespace characters
set linebreak
let &listchars='tab:▸ ,space:·,nbsp:_,trail:·,eol:¬'
let &showbreak='↪ '                         " string to put at the start of lines that have been wrapped
set backspace=indent,eol,start              " configure backspace so it acts as it should act
let g:indentLine_enabled = 0                " Plugin 'Yggdroot/indentLine'
let g:indentLine_char = '·'                 " Character to be used as indent line.

augroup OverrideWhitespaceSettings
  autocmd!
  " change working directory to project root
  autocmd BufEnter * :Rooter
  " strip all trailing whitespace everytime you save the file
  autocmd BufWritePre * :StripWhitespace
  " replace tabs with spaces
  autocmd BufWritePre * if &filetype != 'go' | :retab | endif

  " override whitespace settings
  autocmd FileType go setlocal noexpandtab shiftwidth=4 tabstop=4 softtabstop=4
  autocmd FileType vim setlocal tabstop=2 shiftwidth=2 softtabstop=2 expandtab
  autocmd FileType yaml setlocal tabstop=2 shiftwidth=2 softtabstop=2 expandtab
  autocmd FileType ansible setlocal tabstop=2 shiftwidth=2 softtabstop=2 expandtab
  autocmd FileType html setlocal tabstop=2 shiftwidth=2 softtabstop=2 expandtab
  autocmd FileType hive setlocal expandtab
  autocmd FileType ruby,haml,eruby,sass,cucumber setlocal tabstop=2 shiftwidth=2 softtabstop=2 expandtab
augroup END

" To ensure that plugin works well with Tim Pope's fugitive
" and to avoid loading EditorConfig for any remote files over ssh
let g:EditorConfig_exclude_patterns = ['fugitive://.*', 'scp://.*']

"
" Autocomplete (Insert mode CTRL+N/CTRL+P)
"
set dictionary+=~/.vim/bundle/bootstrap-snippets/dictionary
set complete+=k
let g:SuperTabDefaultCompletionType = "context"
let g:SuperTabContextDefaultCompletionType = '<C-n>'    " navigate the completion menu from top to bottom

"
" Status Line
"
if !exists('g:airline_symbols')
  let g:airline_symbols = {}
endif

let g:airline_left_sep = ''
let g:airline_left_alt_sep = ''
let g:airline_right_sep = ''
let g:airline_right_alt_sep = ''
let g:airline_symbols.readonly = '[RO]'

if has('macunix') || system('uname') =~ 'Darwin'
  let g:airline_symbols.linenr = '␤'
  let g:airline_symbols.branch = '⎇'
else
  let g:airline_symbols.linenr = 'LN'
  let g:airline_symbols.branch = 'BR'
endif

augroup StatusLine
  autocmd!
  autocmd ColorScheme PaperColor :AirlineTheme papercolor
augroup END

" Enable the list of buffers
" let g:airline#extensions#tabline#enabled = 1
" Show just the filename
" let g:airline#extensions#tabline#fnamemod = ':t'

"
"  GUI/Terminal
"
if has("gui_running")          " GUI is running or is about to start
  set guioptions-=m            " remove menu bar
  set guioptions-=T            " remove toolbar
  " set guioptions+=T            " add toolbar
  set guioptions-=l            " remove left scrollbar
  set guioptions-=L            "   when there is a vertically split window
  set guioptions-=r            " remove right scrollbar
  set guioptions-=R            "   when there is a vertically split window

  function! ToggleToolbar()
    if &guioptions =~ 'T'
      exec('set guioptions-=T')
    else
      exec('set guioptions+=T')
    endif
  endfunction

  map <F9> <Esc>:call ToggleToolbar()<CR>

  set lines=41 columns=145     " window size
  " set guifont=Menlo:h14
  set guifont=Monaco:h14

  colorscheme solarized
  " colorscheme PaperColor

  if g:colors_name =~ 'solarized'
    let hour = strftime("%H")
    if 6 <= hour && hour < 18
      set background=light
    else
      set background=dark
    endif
    call togglebg#map("<F5>")
  elseif g:colors_name =~ 'PaperColor'
    set background=light
    let g:airline_theme = 'papercolor'
  endif
else                           " this is console Vim
  set t_Co=256                 " 256 colors

  if exists('$ITERM_PROFILE')  " sync Vim and iTerm colors
    " sync background
    if $ITERM_PROFILE =~ "Light"
      set background=light
    else
      set background=dark
    endif
    " sync colorscheme
    if $ITERM_PROFILE =~ "Solarized"
      colorscheme solarized
    elseif $ITERM_PROFILE =~ "PaperColor"
      colorscheme PaperColor
      let g:airline_theme = 'papercolor'
    elseif $ITERM_PROFILE =~ "jellybeans"
      colorscheme jellybeans
    elseif $ITERM_PROFILE =~ "heroku"
      colorscheme heroku-terminal
    elseif $ITERM_PROFILE =~ "iceberg"
      colorscheme iceberg
    endif
  else                         " Terminal.app
    set background=dark
    colorscheme solarized
  endif
endif

"
"  Mappings
"
let mapleader = " "

" Quickly edit/reload the vimrc file
nmap <silent> <leader>ev :e $MYVIMRC<CR>
nmap <silent> <leader>sv :so $MYVIMRC<CR>

" clearing highlighted search
nmap <silent> <Leader>/ :nohlsearch<CR>
nmap <silent> <Leader><Space> :nohlsearch<CR>

" show identation
map <F2> :set list!<CR>:IndentLinesToggle<CR>

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
inoremap <S-Down> <C-o>vj
inoremap <S-Left> <C-o>h<C-o>v
inoremap <S-Right> <C-o>v

" Escape key alternatives
inoremap jj <Esc>
inoremap jk <Esc>
inoremap kj <Esc>

" Copy & paste to system clipboard with <Space>p and <Space>y
vmap <Leader>y "+y
vmap <Leader>d "+d
nmap <Leader>p "+p
nmap <Leader>P "+P
vmap <Leader>p "+p
vmap <Leader>P "+P

" IDE like autocompletion
imap <C-Space> <Plug>snipMateTrigger

"
" CtrlSpace: tabs / buffers / files management
"
let g:CtrlSpaceUseUnicode = 0
let g:CtrlSpaceCacheDir = $HOME.'/.vim/cache/ctrlspace'
" let g:CtrlSpaceLoadLastWorkspaceOnStart = 1
" let g:CtrlSpaceSaveWorkspaceOnSwitch = 1
" let g:CtrlSpaceSaveWorkspaceOnExit = 1

"
" CtrlP: Full path fuzzy file finder
"
map <leader>t :CtrlP<CR>
map <leader>e :CtrlPMRU<CR>
map <leader>b :CtrlPBuffer<CR>

let g:ctrlp_map = '<C-p>'               " default mapping
let g:ctrlp_cmd = 'CtrlP'               " default command
let g:ctrlp_working_path_mode = 'ra'    " set local working directory
let g:ctrlp_by_filename = 1             " searching by filename (as opposed to full path)
let g:ctrlp_match_window_reversed = 0   " show the results from top to bottom
let g:ctrlp_match_window = 'bottom,order:ttb,min:1,max:15,results:15'

if executable('ag')
  " Use Ag over Grep
  set grepprg=ag\ --nogroup\ --nocolor
  " Use ag in CtrlP for listing files. Lightning fast and respects .gitignore
  let g:ctrlp_user_command = 'ag -l --nocolor -g "" %s'
  " ag is fast enough that CtrlP doesn't need to cache
  let g:ctrlp_use_caching = 0
else
  let g:ctrlp_show_hidden = 1
  let g:ctrlp_cache_dir = $HOME.'/.vim/cache/ctrlp'
  let g:ctrlp_custom_ignore = {
      \ 'dir':  '\v[\/](\.(git|idea|hg|svn|vagrant|settings|gradle))|(target|classes|build|dist|bower_components|node_modules)$',
      \ 'file': '\v\.(iml|eml|ipr|iws|project|classpath|class|jar|war|ear|zip|pyc|pyo|obj|o|a|db|jpeg|jpg|png|gif|exe|so|dylib|dll|pdf)$',
      \ }
endif

"
" vim-session: extended session management for Vim http://peterodding.com/code/vim/session/
"
set sessionoptions-=options         " Don't persist options and mappings because it can corrupt sessions.
set sessionoptions-=buffers         " Don't save hidden and unloaded buffers in sessions.
set sessionoptions-=help            " If you don't want help windows to be restored

if has("gui_running")
  let g:session_autosave = 'yes'
  let g:session_autoload = 'yes'
  " let g:session_autoload = 'prompt'
else
  let g:session_autosave = 'no'
  let g:session_autoload = 'no'
endif
let g:session_command_aliases = 1
let g:session_lock_enabled = 0
let g:session_default_overwrite = 1

"
" Tagbar: source code navigation
"
map <F8> :TagbarToggle<CR>

let g:tagbar_type_ansible = { 'ctagstype' : 'ansible', 'kinds' : [ 't:tasks' ], 'sort' : 0 }
let g:tagbar_type_markdown = { 'ctagstype' : 'markdown', 'kinds' : [ 'h:Heading_L1', 'i:Heading_L2', 'k:Heading_L3' ] }
let g:tagbar_type_puppet = { 'ctagstype': 'puppet', 'kinds': ['c:class','s:site','n:node','d:definition']}
let g:tagbar_type_r = { 'ctagstype' : 'r', 'kinds' : [ 'f:Functions', 'g:GlobalVariables', 'v:FunctionVariables', ] }
let g:tagbar_type_ruby = { 'kinds' : [ 'm:modules', 'c:classes', 'd:describes', 'C:contexts', 'f:methods', 'F:singleton methods' ] }
let g:tagbar_type_typescript = { 'ctagstype': 'typescript', 'kinds': [ 'c:classes', 'n:modules', 'f:functions', 'v:variables', 'v:varlambdas', 'm:members', 'i:interfaces', 'e:enums', ] }
let g:tagbar_type_xml = { 'ctagstype' : 'WSDL', 'kinds' : [ 'n:namespaces', 'm:messages', 'p:portType', 'o:operations', 'b:bindings', 's:service' ] }
let g:tagbar_type_xquery = { 'ctagstype' : 'xquery', 'kinds' : [ 'f:function', 'v:variable', 'm:module', ] }
let g:tagbar_type_xsd = { 'ctagstype' : 'XSD', 'kinds' : [ 'e:elements', 'c:complexTypes', 's:simpleTypes' ] }
let g:tagbar_type_xslt = { 'ctagstype' : 'xslt', 'kinds' : [ 'v:variables', 't:templates' ]}
let g:tagbar_type_go = {
    \ 'ctagstype' : 'go',
    \ 'kinds'     : [
        \ 'p:package', 'i:imports:1', 'c:constants', 'v:variables', 't:types', 'n:interfaces', 'w:fields', 'e:embedded', 'm:methods', 'r:constructor', 'f:functions'
    \ ],
    \ 'sro' : '.',
    \ 'kind2scope' : { 't' : 'ctype', 'n' : 'ntype' },
    \ 'scope2kind' : { 'ctype' : 't', 'ntype' : 'n' },
    \ 'ctagsbin'  : 'gotags', 'ctagsargs' : '-sort -silent'
\ }

"  Change Vim cursor shape in different modes
if exists('$TMUX')
  let &t_SI = "\<Esc>Ptmux;\<Esc>\e[5 q\<Esc>\\"
  let &t_EI = "\<Esc>Ptmux;\<Esc>\e[2 q\<Esc>\\"
elseif exists('$TERM_PROGRAM') && $TERM_PROGRAM =~ "iTerm.app"
  let &t_SI = "\e[5 q"
  let &t_EI = "\e[2 q"
endif

" For (sort of) modern standards in :TOhtml output
let g:html_use_css   = 1
let g:html_use_xhtml = 0

" EOF
