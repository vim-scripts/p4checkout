" =============================================================================
" File:          autoload/p4checkout.vim
" Description:   Automatically try to check out read-only files from Perforce
" Author:        Adam Slater <github.com/aslater>
" =============================================================================

function! p4checkout#Strip(input_string)
    return substitute(a:input_string, '^\s*\(.\{-}\)\s*$', '\1', '')
endfunction

function! p4checkout#ReadP4Info(filename)
   let b:p4localdir = fnamemodify(a:filename, ':p:h')

   let p4info = readfile(a:filename) + ["", ""]
   let b:p4cmd = 'p4'
   "echo p4info
   for line in p4info
      "echo line
      let splitline = split(line, '=')
      "echo splitline
      if len(splitline) > 1
         let var = p4checkout#Strip(splitline[0])
         "echo var
         let value = p4checkout#Strip(join(splitline[1:], '='))
         "echo value

         if var ==? "p4workspace"
            let b:p4cmd .= ' -c ' . value
         elseif var ==? "p4path"
            let b:p4repodir = value
         elseif var ==? "p4user"
            let b:p4cmd .= ' -u ' . value
         elseif var ==? "p4pass"
            let b:p4cmd .= ' -P ' . value
         elseif var ==? "p4port"
            let b:p4cmd .= ' -p ' . value
         endif
      endif
   endfor
   "echo b:p4cmd
   "echo "got p4 info:"
   "echo dirname
   "echo p4info[0]
   "echo p4info[1]
endfunction

function! p4checkout#FindP4Info(dirname)
   "echo \"looking for p4 info in\"
   "echo a:dirname
   let files = split(globpath(a:dirname, '*'), '\n')

   for file in files
      if !isdirectory(file)
         if fnamemodify(file, ':t') ==? "p4root.txt"
            "echo "got match" 
            "echo file
            call p4checkout#ReadP4Info(file)
         endif
      endif
   endfor

   let newdir = fnamemodify(a:dirname, ':p:h:h')

   " If we've run out of parent directories, hang our head in shame and return
   if !(newdir ==# a:dirname)
      call p4checkout#FindP4Info(newdir)
   else
      return
   endif
endfunction

" Set a buffer-local variable to the perforce path, if this file is under the perforce root.
function! p4checkout#IsUnderPerforce()
   if !exists('b:p4checked')
      "echo expand('%:p')
      call p4checkout#FindP4Info(expand('%:p:h'))
      if exists('b:p4repodir')
         "echo 'replacing ' . p4localdir . ' with ' . p4repodir . ' in ' . expand('%:p')
         let b:p4path = substitute(expand("%:p"), escape(b:p4localdir, ' \'), escape(b:p4repodir, ' \'), "")
         let b:p4path = substitute(b:p4path, '\', '/', 'g')
         echo "got " . b:p4path
      endif
      let b:p4checked = 1
   endif
endfunction

" Confirm with the user, then checkout a file from perforce.
function! p4checkout#P4Checkout()
   call p4checkout#IsUnderPerforce()
   if exists("b:p4path")
      call system(b:p4cmd . ' sync ' . b:p4path . ' > /dev/null')
      call system(b:p4cmd . ' edit ' . b:p4path . ' > /dev/null')
      echo b:p4cmd . ' sync ' . b:p4path . ' > /dev/null'
      echo b:p4cmd . ' edit ' . b:p4path . ' > /dev/null'
      if v:shell_error == 0
         set noreadonly
         edit
      endif
   endif
endfunction
