
Vim's system('string') interface is not always straightforward in Windows,
its behaviour can be downright unexpected involves an intricate set of options. Its primary purpose its to execute
a command in the shell (see `&shell`) in simple terms we can think that calling `system('some command')` is equivalent
to spawning a process with the following arguments

```
[&shell, &shellcmdflag, 'some command']
```

and sometimes this might be true but it also might not. Consider the following examples (I'm running in gVim 7.4/Windows 8)

```vim
set shell=powershell shellquote=\" shellpipe=\| shellredir=>
set shellcmdflag=-Command
let &shellxquote=' '

" this works
echo system('echo a')

" this is a valid powershell expression and should print the line
"     a b
" instead it prints them on separate lines
echo system('echo "a b"')
```

To help figure out what is going on I've grabbed the printargs-test.exe binary from the Neovim functional tests, it prints the command line arguments it gets, separated by `;`.

```vim
" this a test program used by neovim to debug command arguments
set shell=c:\msys64\home\dummy\neovim\build\bin\printargs-test.exe

" this one prints arg1:-Command;arg2:echo;arg3:a;
echo system('echo a')
" this one prints arg1:-Command;arg2:echo;arg3:a b;
echo system('echo "a b"')
```

The first command works but it does not produce the expected command arguments it is called as

```
[&shell, -Command, echo, a]
```

The second case is even more surprising

```
[&shell, -Command, echo, a b]
```

and notice that the double quotes `"a b"` were lost, those were a meaningful part of the powershell expression. That is why the output does not match what we expect.

To understand what happened you first need to know that in windows when spawning a process, arguments are represented as a string. This makes it dificult to know where one argument stops and the other begins, but there a convention for this documented [here](https://msdn.microsoft.com/en-us/library/17w5ykft(v=vs.85).aspx), I assume most modern programs follow it by using [this function](https://msdn.microsoft.com/en-us/library/bb776391(v=vs.85).aspx) but the cmd.exe shell [does not](https://blogs.msdn.microsoft.com/twistylittlepassagesallalike/2011/04/23/everyone-quotes-command-line-arguments-the-wrong-way/).

Try this

```vim
" this is what we wanted arg1:-Command;arg2:echo "a b"
echo system('"echo \"a b\""')
```

i.e.

```
[&shell, -Command, echo "a b"]
```

Actually my initial examples were a bit disonest, since they went straight for powershell. To understand why Vim does it this way you need to understand that UNIX systems have ways to handle argv correctly, but since in Vim in Windows works mostly around cmd.exe, then it makes sense that `system()` does not immediately work with other shells. The specific problem in Windows is that system() not only needs to build a valid shell command it also needs to build a valid command according to whatever convention your shell uses, and cmd.exe is different from other windows programs.

Another way to put it is that in windows, shell command construction gets mixed up with process argument construction. There are several historical reasons for this, for example Vim redirects process output to temporary files when calling system().

### Windows argument quoting according to convention

Vim has several options related to shell invocation

- shellquote
- shellxquote
- shellxescape
- shellpipe
- shellredir
- shellcmdflag
- shellescape()

These help you define how system calls the shell process.
For example as a test, I've tried to follow up the previous examples with this

```Vim
" this is one step closer to correct quoting, but it only works in Neovim
" in Vim it fails to open the redirect tmp file
set shellxquote=\"
echo system('echo \"a b\"')
```

I don't think we can implement proper quoting through the Vim options alone, AFAIK the only option that influences the contents of the string passed to `system()` is `shellxescape` but this option is only used if `shellxquote=(` which we don't really want for this case.

The included vimscript is an attempt to write a function to build process arguments in vimscript. It definitely DOES NOT work for cmd.exe, it is meant for conformant shells in windows. It basically does in vimscript what libuv did for Neovim's system('...') prior to #6359. The `tests.vim` file runs a bunch of assertions over it.

### References

- [Everyone quotes command line arguments the wrong way](https://blogs.msdn.microsoft.com/twistylittlepassagesallalike/2011/04/23/everyone-quotes-command-line-arguments-the-wrong-way)
- [An extensive writeup on system() behaviour and various Vim options](https://github.com/airblade/vim-system-escape)


