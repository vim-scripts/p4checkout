" =============================================================================
" File:          plugin/p4checkout.vim
" Description:   Automatically try to check out read-only files from Perforce
" Author:        Adam Slater <github.com/aslater>
" =============================================================================

if exists("g:loaded_p4checkout_plugin")
   finish
endif

let g:loaded_p4checkout_plugin = 1

autocmd FileChangedRO * call p4checkout#P4Checkout()
