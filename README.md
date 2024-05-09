# A low-configuration Makefile

Best used with `make -s` to silence command invocations.

This makefile is intended to be included in a top-level Makefile, like:

```
OBJECTS = src/main.o src/foo.o src/bar.o

include deps/c-build/build.mk
```

Features:

  * Header file dependency tracking (it runs the C compiler with `-MMD` to )
  * Generate `compile_commands.json`

Caveats:

  * Literal definition of "works on my machine".
