
source win32quotearg.vim

" first lets test our function for sanity
let v:errors = []
call assert_equal('"hello\"world"', QuoteW32Arg('hello"world'))
call assert_equal('hello\"world', QuoteW32Arg('hello"world', 0))
call assert_equal('"hello\"\"world"', QuoteW32Arg('hello""world'))
call assert_equal('hello\world', QuoteW32Arg('hello\world'))
call assert_equal('hello\\world', QuoteW32Arg('hello\\world'))
call assert_equal('"hello\\\"world"', QuoteW32Arg('hello\"world'))
call assert_equal('"hello\\\\\"world"', QuoteW32Arg('hello\\"world'))
call assert_equal('"hello world\\"', QuoteW32Arg('hello world\'))

call assert_equal('""', QuoteW32Arg(''))
call assert_equal('', QuoteW32Arg('', 0))
call assert_equal('"hello world"', QuoteW32Arg('hello world'))
call assert_equal('hello world', QuoteW32Arg('hello world', 0))

" The following are default in Neovim functional tests w/ powershell
" lets go with that for now
set shell=powershell shellquote=\" shellpipe=\| shellredir=>
set shellcmdflag=-Command
let &shellxquote=' '

" a quick sanity test for the shell
call assert_equal("a\n", system('echo a'))
call assert_equal(0, v:shell_error)

call assert_equal("a b\n", system(QuoteW32Arg('echo "a b"')))

for err in v:errors
	echoerr err
endfor

if exists('g:quit_after_tests')
	if len(v:errors) > 0
		echoerr "Tests failed!"
		cquit
	else
		quit
	endif
endif
