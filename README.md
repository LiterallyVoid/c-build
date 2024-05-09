# A low-configuration Makefile

Best used with `make -s` to silence command invocations.

This makefile is intended to be included in a top-level Makefile, like:

```make
OBJECTS = src/main.o src/foo.o src/bar.o

INCLUDES = include/

# Package names passed to `pkg-config`
PACKAGES = openssl

include deps/c-build/build.mk
```

Features:

  * Header file dependency tracking (it runs the C compiler with `-MMD` to )
  * Generate `compile_commands.json`

Caveats:

  * Literal definition of "works on my machine".
