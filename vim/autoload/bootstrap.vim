"
" http://erikzaadi.com/2012/03/19/auto-installing-vundle-from-your-vimrc/
"

function! bootstrap#vundle()
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
    call vundle#begin()
endfunction

function! bootstrap#plugins()
    call vundle#end()
    if s:install_plugins == 1
        :PluginInstall
    endif
endfunction
