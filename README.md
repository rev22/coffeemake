This is a simple programmable build tool with minimal dependencies, just Node.js and Coffeescript.

Command usage and functionality are similar to 'make':

```sh
coffee Makefile.coffee [TARGET]
```

but also supports the 'watch' feature of more modern build tools, for rebuilding files when their sources change:

```sh
coffee Makefile.coffee --watch [TARGET]
```

## Installation:

First copy `coffeemakefile.coffee` to your buildtree for example under `scripts/`.

Then create a Makefile.coffee, like this one. 

```coffee
require('./coffeemakefile').run ->
	@var 'cc' # Define cc as a variable

	# Define rule for generating .o files from .c files
	@ '%.o', '%.o', ->
		@sh @v.cc @in, '-o', @out

```

This may look familiar to you if you both know 'make' and 'Coffeescript'.


## Authors and licensing

Copyright (c) 2014 Michele Bini

MIT license.
