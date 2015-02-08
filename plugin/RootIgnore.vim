" Vim plugin that finds .gitignore in repo root and sets wildignore from it 
" Adapted from gitignore <http://www.vim.org/scripts/script.php?script_id=2557>
" by Adam Bellaire
" Author: Pine Wu <https://github.com/octref>
" License: MIT

" Usage
"
" This plugin is designed to complement CtrlP & Command-T
" There is no apparent way to
" 1: Restrict search results to files under current directory
" 2: Honor .gitignore in repo root
" Adam Bellaire's script honors .gitignore when Vim is opened at repo root,
" but not when Vim is opened in subfolders under repo root.
" For example, when you cd foo/bar/ and open Vim, and suppose
" foo/.gitingore ignores _*, CtrlP ignores foo/bar/_build and all results are
" under foo/bar/

function! s:WildignoreFromGitignore(gitpath, isAtRoot)
  let gitignore = a:gitpath . "/.gitignore"
  if filereadable(gitignore)
    let igstring = ''
    for oline in readfile(gitignore)

      let line = substitute(oline, '\s|\n|\r', '', "g")
      if line =~ '^#' | con | endif
      if line == ''   | con | endif
      if line =~ '^!' | con | endif

      if a:isAtRoot
        if line =~ '/$' 
          let igstring .= "," . line . "*"
        else
          let igstring .= "," . line
        endif
      else
        let fullPath = a:gitpath . "/" . line

        if line =~ "/"
          if fullPath =~ getcwd()
            let pattern = fnamemodify(fullPath, ":.")
            if pattern =~ "/$" 
              pattern .= "*" 
            endif
            let igstring .= "," . pattern
          endif
        else
          let igstring .= "," . line
        endif
      endif

    endfor
    execute "set wildignore+=" . substitute(igstring, '^,', '', "g")

    " Set ag's ignore
    if exists("g:RootIgnoreAgignore") && g:RootIgnoreAgignore
      let agignore = ''
      for oline in readfile(gitignore)
        let line = substitute(oline, '\s|\n|\r', '', "g")
        if line =~ '^#' | con | endif
        if line == ''   | con | endif
        if line =~ '^!' | con | endif
        if line =~ '/$' | let igstring .= "," . line . "*" | con | endif
        let agignore .= " --ignore '" . line . "'"
      endfor
      let agcommand = 'ag %s -i --nocolor -g ""' . agignore
      let g:ctrlp_user_command = [
          \ '.git', agcommand,
          \ 'find %s -type f'
          \ ]
    endif
  endif

endfunction

function! s:RootIgnore()
  let gitdir = finddir(".git", ";")
  if gitdir != ""
    if gitdir == ".git" 
      let gitpath = getcwd()
      let isAtRoot = 1
    elseif gitdir =~ "/"
      let gitpath = fnamemodify(gitdir, ":h")
      let isAtRoot = 0
    endif
    call s:WildignoreFromGitignore(gitpath, isAtRoot)
  endif
endfunction

call s:RootIgnore()
