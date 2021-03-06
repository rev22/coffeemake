Simple build tool for Node.js, fully programmable via Coffeescript

Command usage and functionality are similar to 'make':

```sh
coffeemake TARGET
```

it also supports the 'watch' feature of more modern build tools, for rebuilding files when their sources change:

```sh
coffeemake --watch TARGET
```

Build rules are extracted from Makefiles.   Makefiles with very simple traditional syntax are supported, for example:

```make
CC=cc

%.o: %.c
	$(CC) $< -o $@
```

Only this very simple subset of the traditional syntax is currently supported.


Complex Makefiles should be written using a Coffeescript syntax, also allowing you to define build rules as as javascript functions, in addition to shell commands.

The syntax should be intuitive and familiar to you if you are already acquainted with Coffeescript and 'make':

```coffee
require('coffeemake').run ->

	@var 'cc' # Define cc as a variable

	# Define rule for generating .o files from .c files
	@ '%.o', '%.c', ->
		@sh @v.cc, @in, '-o', @out
		# You can add any code for the build rule here

```

These Coffeescript-defined makefiles should be run stand-alone:

```
coffee Makefile.coffee TARGET
```


## Installation

The easiest way to install is via npm, for example:

```sh
npm install coffeemake
```


## Command-line options

```
  -f FILE    Read FILE as Makefile
  --watch    Rebuild targets when the current directory for changes
  --test     Test run: print shell commands instead of executing them
  --rebuild  Rebuild targets ignoring modification times
  --quiet    Do not show messages
  --verbose  Increase verboseness
  --help     Show this help
```

Like `make`, `coffeemake` also accepts a `-f FILE` option, for specifying additional Makefiles in the traditional Makefile format


## Known bugs and limitations

The 'watch' feature only watches for changes in the current directory. 

Command-line usage is not yet standardized or generally compatible with `make`.

These may be fixed in later versions.


## Authors and licensing

Copyright (c) 2014 Michele Bini

MIT license
