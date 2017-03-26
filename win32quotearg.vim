" ported from libuv/quote_cmd_arg - quotes a single argument for calling a
" process. This works well for quoting arguments for windows shells that
" follow the expected argument convention (cmd.exe DOES NOT), at least
" assuming that you want to pass your entire command as single argument to
" your shell e.g. powershell -Command <...Shell cmd>
"
" Usage:
"	QuoteW32Arg(str)
"	QuoteW32Arg(str, 0)
"
" If the optional second argument is not 1 it disables wrapping in double quotes.
"
" NOTE: its unclear to me if this clashes with &shellquote=" when used as
"       system(QuoteW32Arg('...))
function! QuoteW32Arg(arg, ...)
	let wrap = (a:0 >= 1) ? a:1 : 1
	if strlen(a:arg) == 0
		" empty arguments use double quotes
		return (wrap == 1) ? '""' : '' 
	endif

	if a:arg !~ '"' && a:arg !~ "\t" && a:arg !~ ' '
		" no quotation needed
		return a:arg
	endif

	if a:arg !~ '\' && a:arg !~ '"'
		" no inner double quotes or backslashes, wrap in double quotes
		return (wrap == 1) ? '"'.a:arg.'"' : a:arg
	endif

	let revcmd = reverse(split(a:arg, '.\zs'))
	let target = ''
	let quote_hit = 1
	for c in revcmd
		let target = target . c

		if quote_hit == 1 && c == '\'
			" double backslash
			let target = target . '\'
		elseif c == '"'
			let quote_hit = 1
			" double quote
			let target = target . '\'
		else
			let quote_hit = 0
		endif
	endfor
	let result = join(reverse(split(target, '.\zs')), '')
	return (wrap == 1) ? '"'.result.'"' : result
endfunction

