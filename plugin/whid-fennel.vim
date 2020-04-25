" plugin/whid-fennel.vim
if exists('g:loaded_whid_fennel') | finish | endif

let s:save_cpo = &cpo
set cpo&vim

hi def link WhidHeader      Number
hi def link WhidSubHeader   Identifier

command! MP lua require'whid-fennel.init'.whid()

let &cpo = s:save_cpo
unlet s:save_cpo

let g:loaded_whid_fennel = 1
