" Vim syntax file
" Language:	dudl musicDB template
" Maintainer:	Rainer Clasen <rc@zuto.de>
" Last Change:	2001 Aug 19

" I've copied this to ~/.vim/syntax and added the following to my .vimrc:
"   au! Syntax dudlmus     source ~/.vim/syntax/dudlmus.vim

" clear any unwanted syntax defs
syn clear

" shut case off
syn case ignore

syn match  dudlmusAlbumKey	"^[[:space:]]*album_[[:alnum:]]\{1,\}"
syn match  dudlmusFileKey	"^[[:space:]]*file_[[:alnum:]]\{1,\}"
syn match  dudlmusComment	"^[[:space:]]*#.*$"

if !exists("did_dudlmus_syntax_inits")
	let did_dudlmus_syntax_inits = 1
	" The default methods for highlighting.  Can be overridden later
	hi link dudlmusAlbumKey	Identifier
	hi link dudlmusFileKey	Type
	hi link dudlmusComment	Comment

endif

let b:current_syntax = "dudlmus"

" vim:ts=8
