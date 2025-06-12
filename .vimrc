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
set termguicolors              " enable 24-bit RGB color in the terminal
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
set shortmess=aoOtTlfmnr
set autochdir                  " change the current working directory whenever you open a file, switch buffers, delete a buffer or open/close a window
set hidden
set timeout                    " time out for mappings
set timeoutlen=1000            " wait 1s to let me finish typing the left-hand-side of a mapping
set ttimeout                   " time out for key codes
set ttimeoutlen=50             " wait up to 50ms after Esc for special key

if has('macunix') || system('uname') =~ 'Darwin'
  set shell=zsh
else
  set shell=bash
endif

set wildignore+=.DS_Store,._*,Thumbs.db,.netrwhist
set wildignore+=.git/*,.hg/*,.svn/*,.vagrant/*,.gradle/*

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
Plugin 'tacahiroy/ctrlp-funky'              " A super simple function navigator for ctrlp.vim
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
" Plugin 'fatih/vim-go'                       " Go development plugin for Vim
Plugin 'Glench/Vim-Jinja2-Syntax'           " An up-to-date jinja2 syntax file
Plugin 'vim-scripts/Vim-R-plugin'
Plugin 'motus/pig.vim'                      " Pig syntax highlighting
Plugin 'rverk/snipmate-pig'                 " PigLating snippets for snipmate
Plugin 'autowitch/hive.vim'                 " Syntax highlighting for Hive
Plugin 'bonsaiben/bootstrap-snippets'       " Bootstrap 3.2 markup snippets for vim-snipmate
Plugin 'Omer/vim-sparql'                    " syntax file for SPARQL
Plugin 'sboehler/jflex-vim'                 " JFlex
Plugin 'dylon/vim-antlr'                    " ANTLR v3 and v4

" command-line tools integration
Plugin 'tpope/vim-fugitive'                 " Git wrapper so awesome, it should be illegal
Plugin 'mileszs/ack.vim'                    " Vim frontend for the Perl module App::Ack
Plugin 'rking/ag.vim'                       " Vim frontend for the Ag, aka the_silver_searcher
Plugin 'majutsushi/tagbar'                  " plugin that displays tags in a window, ordered by scope
Plugin 'scrooloose/syntastic'               " Syntax checking hacks for vim
Plugin 'lambdalisue/vim-gita'               " An awesome git handling plugin

" color schemes
Plugin 'altercation/vim-colors-solarized'   " http://ethanschoonover.com/solarized
Plugin 'nlknguyen/papercolor-theme'         " Inspired by Google's Material Design
Plugin 'ayu-theme/ayu-vim'
Plugin 'catppuccin/vim'                     " Catppuccin color scheme for Vim a warm and fuzzy pastel theme https://catppuccin.com/

" LLM, Copilot, etc
Plugin 'github/copilot.vim'

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
  autocmd BufRead,BufNewFile playbook.yml,site.yml,setup.yml,main.yml setlocal filetype=yaml.ansible
  autocmd BufRead,BufNewFile */*ansible*/*.yml,*/playbooks/*.yml,*/tasks/*.yml,*/roles/*.yml,*/vars/*.yml,*/*_vars/*.yml,*/handler/*.yml,*/handlers/*.yml setlocal filetype=yaml.ansible
  autocmd BufRead,BufNewFile hosts,*/defaults/*,*/inventory/* setlocal filetype=yaml.ansible
  autocmd BufRead,BufNewFile */nginx/*.conf,nginx.conf if &filetype == '' | setfiletype nginx | endif
  autocmd BufRead,BufNewFile Vagrantfile,Rakefile,Capfile,Gemfile,Brewfile setlocal filetype=ruby
  autocmd BufRead,BufNewFile *.html.erb setlocal filetype=html
  autocmd BufRead,BufNewFile *.gradle setlocal filetype=groovy
  autocmd BufRead,BufNewFile *.pig setlocal filetype=pig
  autocmd BufRead,BufNewFile *.hql,*.q setlocal filetype=hive
augroup END

" in order to get full support for Golng I use vim-go plugin directly
" let g:polyglot_disabled = ['go']

" By default syntax-highlighting for Functions, Methods and Structs is disabled
let g:go_highlight_functions = 1
let g:go_highlight_methods = 1
let g:go_highlight_fields = 1
let g:go_highlight_types = 1
let g:go_highlight_operators = 1
let g:go_highlight_build_constraints = 1
let g:go_version_warning = 0

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
let &listchars='tab:❯ ,space:·,nbsp:_,trail:·,eol:¬'
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
  " autocmd BufWritePre * if &filetype != 'go' | :retab | endif

  " override whitespace settings
  autocmd FileType go setlocal noexpandtab shiftwidth=4 tabstop=4 softtabstop=4
  autocmd FileType vim setlocal tabstop=2 shiftwidth=2 softtabstop=2 expandtab
  autocmd FileType yaml setlocal tabstop=2 shiftwidth=2 softtabstop=2 expandtab
  autocmd FileType sh setlocal tabstop=2 shiftwidth=2 softtabstop=2 expandtab
  autocmd FileType ansible setlocal tabstop=2 shiftwidth=2 softtabstop=2 expandtab
  autocmd FileType html setlocal tabstop=2 shiftwidth=2 softtabstop=2 expandtab
  autocmd FileType hive setlocal expandtab
  autocmd FileType ruby,haml,eruby,sass,cucumber setlocal tabstop=2 shiftwidth=2 softtabstop=2 expandtab
augroup END

"
" Ansible syntax
"
let g:ansible_extra_keywords_highlight = 1
" let g:ansible_name_highlight = 'd'    " dim the instances of name: found
let g:ansible_name_highlight = 'b'    " brighten the instances of name: found

" To ensure that plugin works well with Tim Pope's fugitive
" and to avoid loading EditorConfig for any remote files over ssh
let g:EditorConfig_exclude_patterns = ['fugitive://.*', 'scp://.*']

"
" Autocomplete (Insert mode CTRL+N/CTRL+P)
"
set complete+=k
let g:SuperTabDefaultCompletionType = "context"
let g:SuperTabContextDefaultCompletionType = '<C-n>'    " navigate the completion menu from top to bottom

" remove deprication warning
let g:snipMate = { 'snippet_version' : 1 }

"
" Status Line
"
let g:airline_left_sep = ''
let g:airline_left_alt_sep = ''
let g:airline_right_sep = ''
let g:airline_right_alt_sep = ''

if !exists('g:airline_symbols')
  let g:airline_symbols = {}
endif

let g:airline_symbols.linenr = '  '
let g:airline_symbols.maxlinenr = ''
let g:airline_symbols.colnr = ':'
let g:airline_symbols.branch = 'Git:'
let g:airline_symbols.readonly = '[RO]'

if has('macunix') || system('uname') =~ 'Darwin'
  " let g:airline_symbols.linenr = '☰'
  " let g:airline_symbols.linenr = ' ␊:'
  " let g:airline_symbols.linenr = ' ␤:'
  let g:airline_symbols.paste = 'ρ'
  " let g:airline_symbols.paste = 'Þ'
  " let g:airline_symbols.paste = '∥'
  let g:airline_symbols.spell = 'Ꞩ'
  let g:airline_symbols.notexists = 'Ɇ'
  let g:airline_symbols.whitespace = 'Ξ'
  let g:airline_symbols.branch = '⎇'
  let g:airline_symbols.crypt = '🔒'
  let g:airline_symbols.readonly = '🔒'
endif

" augroup OpenInTab
"   autocmd!
"   autocmd BufAdd,BufNewFile * nested if &filetype != "help" | tab sball | endif
" augroup END

let g:airline#extensions#tabline#enabled = 1
let g:airline#extensions#tabline#show_splits = 0
let g:airline#extensions#tabline#show_buffers = 0
let g:airline#extensions#tabline#show_tabs = 1
let g:airline#extensions#tabline#show_tab_type = 0
let g:airline#extensions#tabline#show_tab_nr = 0
let g:airline#extensions#tabline#show_close_button = 0
let g:airline#extensions#tabline#close_symbol = '×'
let g:airline#extensions#tabline#fnamemod = ':t'
let g:airline#extensions#tabline#buffer_min_count = 2
let g:airline#extensions#tabline#tab_min_count = 2
let g:airline#extensions#tabline#left_sep = ''
let g:airline#extensions#tabline#left_alt_sep = ''
let g:airline#extensions#tabline#right_sep = ''
let g:airline#extensions#tabline#right_alt_sep = ''

augroup StatusLine
  autocmd!
  autocmd ColorScheme PaperColor let g:airline_theme = 'papercolor'
augroup END

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

  " set guifont=Menlo:h14
  set guifont=Monaco:h14
  " let &guifont='Fira Code:h14'

  if &guifont =~ 'Monaco'
    set lines=42 columns=178
  else
    " set lines=48 columns=145
    set lines=60 columns=200
  endif

  colorscheme solarized
  " colorscheme PaperColor
  " colorscheme ayu

  if g:colors_name =~ 'solarized'
    call togglebg#map("<F5>")
    " set background=light
    set background=dark
  elseif g:colors_name =~ 'PaperColor'
    set background=light
    let g:airline_theme = 'papercolor'
  elseif g:colors_name =~ 'ayu'
    let ayucolor="light"
    " let ayucolor="mirage"
    " let ayucolor="dark"
    set background=light
    " set background=dark
  endif
else                                " this is console Vim
  set t_Co=256                      " 256 colors

  if exists('$ITERM_PROFILE')       " try to sync Vim and iTerm2 background and color scheme
    if $ITERM_PROFILE =~ "Light"
      set background=light          " iTerm2 uses light color presets
    else
      set background=dark           " iTerm2 uses dark color presets
    endif

    if $ITERM_PROFILE =~ "Solarized"
      colorscheme solarized

    elseif $ITERM_PROFILE =~ "PaperColor"
      colorscheme PaperColor
      let g:airline_theme = 'papercolor'

    elseif $ITERM_PROFILE =~ "Ayu Light"
      let ayucolor="light"
      colorscheme ayu
    elseif $ITERM_PROFILE =~ "Ayu Mirage"
      let ayucolor="mirage"
      colorscheme ayu
    elseif $ITERM_PROFILE =~ "Ayu Dark"
      let ayucolor="dark"
      colorscheme ayu

    elseif $ITERM_PROFILE =~ "Catppuccin Latte"
      set background=light
      colorscheme catppuccin_latte
      let g:airline_theme = 'catppuccin_latte'
    elseif $ITERM_PROFILE =~ "Catppuccin Frappé"
      colorscheme catppuccin_frappe
      let g:airline_theme = 'catppuccin_frappe'
    elseif $ITERM_PROFILE =~ "Catppuccin Macchiato"
      colorscheme catppuccin_macchiato
      let g:airline_theme = 'catppuccin_macchiato'
    elseif $ITERM_PROFILE =~ "Catppuccin Mocha"
      colorscheme catppuccin_mocha
      let g:airline_theme = 'catppuccin_mocha'
    endif

  else " no iTerm2 profile, use default color scheme
    set background=dark
    colorscheme catppuccin_frappe
    let g:airline_theme = 'catppuccin_frappe'
  endif
endif

"
"  Mappings
"
let mapleader = " "

noremap <leader>q :q<CR>
noremap <leader>w :bd<CR>
nnoremap <leader>s :w<CR>
inoremap <leader>s <C-c>:w<CR>

" clearing highlighted search
nmap <silent> <Leader>/ :nohlsearch<CR>
nmap <silent> <Leader><Space> :nohlsearch<CR>

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

" when indenting with < and >, make it easy to repeat
vnoremap < <gv
vnoremap > >gv

" Copy & paste to system clipboard with <Space>p and <Space>y
vmap <Leader>y "+y
vmap <Leader>d "+d
nmap <Leader>p "+p
nmap <Leader>P "+P
vmap <Leader>p "+p
vmap <Leader>P "+P

" show identation
noremap <F2> :set list!<CR>:IndentLinesToggle<CR>

" comment
nnoremap // :TComment<CR>
vnoremap // :TComment<CR>

" IDE like autocompletion
imap <C-Space> <Plug>snipMateTrigger

" Quickly edit/reload the vimrc file
nmap <silent> <leader>ev :e $MYVIMRC<CR>
nmap <silent> <leader>sv :so $MYVIMRC<CR>

"
" CtrlP: Full path fuzzy file finder
"
noremap <leader>t :CtrlP<CR>
noremap <leader>e :CtrlPMRU<CR>
noremap <leader>b :CtrlPBuffer<CR>

nnoremap <Leader>fu :CtrlPFunky<Cr>
" narrow the list down with a word under cursor
nnoremap <Leader>uu :execute 'CtrlPFunky ' . expand('<cword>')<Cr>

let g:ctrlp_map = '<C-p>'               " default mapping
let g:ctrlp_cmd = 'CtrlP'               " default command
let g:ctrlp_working_path_mode = 'ra'    " set local working directory
let g:ctrlp_by_filename = 1             " searching by filename (as opposed to full path)
let g:ctrlp_match_window_reversed = 0   " show the results from top to bottom
let g:ctrlp_match_window = 'bottom,order:ttb,min:1,max:15,results:15'

if executable('ag')
  set grepprg=ag\ --nogroup\ --nocolor
  let g:ctrlp_user_command = 'ag -l --nocolor --hidden -g "" %s'
  let g:ctrlp_use_caching = 0
else
  let g:ctrlp_show_hidden = 1
  let g:ctrlp_cache_dir = $HOME.'/.vim/cache/ctrlp'
  let g:ctrlp_custom_ignore = {
      \ 'dir':  '\v[\/](\.(git|idea|hg|svn|vagrant|settings|gradle))|(target|classes|build|dist|bower_components|node_modules)$',
      \ 'file': '\v\.(iml|ipr|iws|project|classpath|class|jar|war|ear|zip|pyc|pyo|obj|o|a|db|jpeg|jpg|png|gif|exe|so|dylib|dll|pdf)$',
      \ }
endif

"
" Copilot
"
"let g:copilot_workspace_folders = [ $HOME.'code',  $HOME.'/src' ]

" To use the local ollama-copilot
"let g:copilot_proxy = 'http://localhost:11435'
"let g:copilot_proxy_strict_ssl = v:false

"
" vim-session: extended session management for Vim http://peterodding.com/code/vim/session/
"
if has("gui_running")
  let g:session_autosave = 'yes'
  let g:session_autoload = 'no'
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

" Support resizing in tmux
if exists('$TMUX')
  set ttymouse=xterm2
endif

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
