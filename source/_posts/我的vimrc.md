---
title: 我的vimrc
date: 2017-06-05 21:56:38
tags:
	- 配置文件
	- vim
categories:
	- 配置文件
---
采用Vundle对插件进行管理。
<!-- more -->
```vim
set nu
syntax on
set smartindent
set smarttab
set sw=4 ts=4 sts=4
set wildmenu
set mousemodel=popup
set cul cuc "高亮光标所在行
set ruler
set scrolloff=4
set laststatus=2
set history=1000
set t_Co=256
set autoread autowrite
set confirm
set nobackup noswapfile

set hlsearch incsearch smartcase

set showmatch

set selectmode=mouse,key

set nocompatible              " be iMproved, required
filetype off                  " required

" set the runtime path to include Vundle and initialize
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()
" alternatively, pass a path where Vundle should install plugins
"call vundle#begin('~/some/path/here')

" let Vundle manage Vundle, required
Plugin 'VundleVim/Vundle.vim'

" The following are examples of different formats supported.
" Keep Plugin commands between vundle#begin/end.
" plugin on GitHub repo
Plugin 'tpope/vim-fugitive'
" plugin from http://vim-scripts.org/vim/scripts.html
" Plugin 'L9'
" Git plugin not hosted on GitHub
Plugin 'git://git.wincent.com/command-t.git'
" git repos on your local machine (i.e. when working on your own plugin)
" Plugin 'file:///home/gmarik/path/to/plugin'
" The sparkup vim script is in a subdirectory of this repo called vim.
" Pass the path to set the runtimepath properly.
Plugin 'rstacruz/sparkup', {'rtp': 'vim/'}
" Install L9 and avoid a Naming conflict if you've already installed a
" different version somewhere else.
" Plugin 'ascenator/L9', {'name': 'newL9'}
Plugin 'scrooloose/nerdtree'
Plugin 'scrooloose/nerdcommenter'

Plugin 'altercation/vim-colors-solarized'
Plugin 'godlygeek/tabular'
Plugin 'plasticboy/vim-markdown'
Plugin 'iamcco/mathjax-support-for-mkdp'
Plugin 'iamcco/markdown-preview.vim'
Plugin 'jiangmiao/auto-pairs'
Plugin 'vim-signature'

Plugin 'easymotion/vim-easymotion'
Plugin 'haya14busa/incsearch.vim'
Plugin 'haya14busa/incsearch-easymotion.vim'

Plugin 'a.vim'

Plugin 'majutsushi/tagbar'
Plugin 'vim-airline/vim-airline'

Plugin 'Valloric/YouCompleteMe'
Plugin 'rdnetto/YCM-Generator'

Plugin 'vimwiki/vimwiki'

Plugin 'skywind3000/asyncrun.vim'
" All of your Plugins must be added before the following line
call vundle#end()            " required
filetype plugin indent on    " required
" To ignore plugin indent changes, instead use:
"filetype plugin on
"
" Brief help
" :PluginList       - lists configured plugins
" :PluginInstall    - installs plugins; append `!` to update or just :PluginUpdate
" :PluginSearch foo - searches for foo; append `!` to refresh local cache
" :PluginClean      - confirms removal of unused plugins; append `!` to auto-approve removal
"
" see :h vundle for more details or wiki for FAQ
" Put your non-Plugin stuff after this line
"

" 设置主题
let g:solarized_termcolors=256
set background=dark
colorscheme solarized

" 配置NerdTree  ************************************************************************
" autocmd vimenter * if !winbufnr(0) | NERDTree | endif  "当打开vim且没有文件时自动打开NERDTree
map <F3> :NERDTreeToggle<CR>
imap <F3> <ESC> :NERDTreeToggle<CR>
" 配置NerdTree  ************************************************************************


" 配置EasyMotion " *********************************************************************
" <Leader>f{char} to move to {char}
map  <Leader>f <Plug>(easymotion-bd-f)
nmap <Leader>f <Plug>(easymotion-overwin-f)

" s{char}{char} to move to {char}{char}
nmap s <Plug>(easymotion-overwin-f2)

" Move to line
map <Leader>L <Plug>(easymotion-bd-jk)
nmap <Leader>L <Plug>(easymotion-overwin-line)

" Move to word
map  <Leader>w <Plug>(easymotion-bd-w)
nmap <Leader>w <Plug>(easymotion-overwin-w)
" You can use other keymappings like <C-l> instead of <CR> if you want to
" use these mappings as default search and somtimes want to move cursor with
" EasyMotion.
function! s:incsearch_config(...) abort
  return incsearch#util#deepextend(deepcopy({
  \   'modules': [incsearch#config#easymotion#module({'overwin': 1})],
  \   'keymap': {
  \     "\<CR>": '<Over>(easymotion)'
  \   },
  \   'is_expr': 0
  \ }), get(a:, 1, {}))
endfunction

noremap <silent><expr> /  incsearch#go(<SID>incsearch_config())
noremap <silent><expr> ?  incsearch#go(<SID>incsearch_config({'command': '?'}))
noremap <silent><expr> g/ incsearch#go(<SID>incsearch_config({'is_stay': 1}))

nnoremap <Esc><Esc> :<C-u>nohlsearch<CR>
" 配置EasyMotion " *********************************************************************

" 配置airline " ***********************************************************************
let g:airline#extensions#tabline#enabled = 1
" 配置airline " ***********************************************************************


" 配置TagBar ××××××××××××××××××××××××××××××××
nmap <F8> :TagbarToggle<CR>
" 配置TagBar ××××××××××××××××××××××××××××××××


" 配置YCM***************************************
let g:ycm_show_diagnostics_ui = 1
let g:ycm_confirm_extra_conf = 0
let g:ycm_seed_identifiers_with_syntax = 0
let g:ycm_key_invoke_completion='<C-i>'
" 配置YCM***************************************

" 自定义快捷键 ******************************************
map <C-L> :tabnext<CR>
map <C-H> :tabprev<CR>
" 自定义快捷键 ******************************************

" 配置Command-t *****************************************
nmap <silent> <Leader>t <Plug>(CommandT)
nmap <silent> <Leader>b <Plug>(CommandTBuffer)
nmap <silent> <Leader>j <Plug>(CommandTJump)
" 配置Command-t *****************************************

" 自动编译 *********************************************
"map <F5> :copen<CR>:wincmd k<CR>:AsyncRun g++ -o %< %<CR>
map <F5> :copen<CR>:wincmd k<CR>:AsyncRun sudo ./build.sh make<CR>
map <Leader><F5> :copen<CR>:wincmd k<CR>:AsyncRun g++ -o %< %;./%<<CR>
" 自动编译 *********************************************


"***** Markdown **************************
set conceallevel=2
let g:vim_markdown_math = 1
let g:vim_markdown_frontmatter = 1
let g:vim_markdown_folding_disabled = 1
let g:mkdp_path_to_chrome = "chromium"
" 设置 chrome 浏览器的路径（或是启动 chrome（或其他现代浏览器）的命令）
let g:mkdp_auto_start = 1
" 设置为 1 可以在打开 markdown 文件的时候自动打开浏览器预览，只在打开
" markdown 文件的时候打开一次
let g:mkdp_auto_open = 1
" 设置为 1 在编辑 markdown 的时候检查预览窗口是否已经打开，否则自动打开预
" 览窗口
let g:mkdp_auto_close = 1
" 在切换 buffer 的时候自动关闭预览窗口，设置为 0 则在切换 buffer 的时候不
" 自动关闭预览窗口
let g:mkdp_refresh_slow = 0
" 设置为 1 则只有在保存文件，或退出插入模式的时候更新预览，默认为 0，实时
" 更新预览
let g:mkdp_command_for_global = 0
" 设置为 1 则所有文件都可以使用 MarkdownPreview 进行预览，默认只有 markdown
" 文件可以使用改命令
"****************************************
nmap <Leader>k :m-2<CR>
nmap <Leader>j :m+<CR>

```
