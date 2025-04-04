# All objects.
OBJECTS ?= \
	src/main.o \
	# more files

# Where to place object files and the final executable
BUILD_DIR ?= build

# Name of the executable, within $(BUILD_DIR)
EXE ?= main

# A list of packages passed to `pkg-config`. If empty, `pkg-config` will not be invoked.
PACKAGES ?= # openssl

# Include directory flags.
INCLUDES ?= # -Iinclude/

# `c2x` because everybody deserves separators within numeric literals
CSTANDARD ?= -std=c2x
CXXSTANDARD ?= -std=c++20

EXPORT_COMPILE_COMMANDS ?= yes

# Warnings.
WARNINGS ?= -Wall -Wextra -Wmissing-prototypes

# Optimization flags.
OPTFLAGS ?= -O0 -g # -O3

# Flags that need to be used during both compilation and linking.
CODEGENFLAGS ?= -fsanitize=undefined -fsanitize=address

# All flags passed to the C compiler to compile both C and C++ files.
CCFLAGS ?= -MMD

CCFLAGS += $(INCLUDES)
CCFLAGS += $(WARNINGS)
CCFLAGS += $(OPTFLAGS)
CCFLAGS += $(CODEGENFLAGS)

# Flags passed for C or C++ files, respectively.
CFLAGS += $(CCFLAGS)
CFLAGS += $(CSTANDARD)

CXXFLAGS +=	$(CCFLAGS)
CXXFLAGS += $(CXXSTANDARD)

# The C compiler used to link this project.
# Set this to $(CXX) if you're writing a C++ project.
CC_LINK ?= $(CC)

# Flags passed to the C compiler to link all object files together into the final executable.
LDFLAGS ?= # -L/usr/lib64/

LDFLAGS += $(CODEGENFLAGS)

ifneq ($(PACKAGES),)
	CFLAGS +=	$(shell pkg-config --cflags $(PACKAGES))
	CXXFLAGS +=	$(shell pkg-config --cflags $(PACKAGES))

	LDFLAGS +=	$(shell pkg-config --libs $(PACKAGES))
endif

MKDIR_P ?= mkdir -p

OBJECTS := $(OBJECTS:%=$(BUILD_DIR)/%)

all: $(BUILD_DIR)/$(EXE) $(BUILD_DIR)/compile_commands.json

ifeq ($(EXPORT_COMPILE_COMMANDS),yes)

all: $(BUILD_DIR)/compile_commands.json

$(BUILD_DIR)/compile_commands.json: $(OBJECTS:%.o=%.compile_commands.json)
	@printf "Exporting %s\n" "$@"
	( echo "["; cat $^; echo "]" ) > $@

endif

$(BUILD_DIR)/$(EXE): $(OBJECTS)
	@printf "Linking %s\n" "$@"

	@$(MKDIR_P) $(@D)

	$(CC_LINK) $^ -o $@ $(LDFLAGS)

# Note: leaves directory structure in place.
clean:
	rm -f $(OBJECTS)
	rm -f $(OBJECTS:%.o=%.d)
	rm -f $(OBJECTS:%.o=%.compile_commands.json)
	rm -f $(BUILD_DIR)/compile_commands.json

	rm -f $(BUILD_DIR)/$(EXE)

.PHONY: clean

# Include all `.d` files, ignoring those that don't exist.
-include $(OBJECTS:%.o=%.d)

# Header files are added as prerequisites by the dependency files (included
# above), but if they don't exist Make looks for a rule to generate them. Add a
# dummy rule so that Make doesn't fail when it can't find those files.
%.h: ;

$(BUILD_DIR)/%.o $(BUILD_DIR)/%.compile_commands.json: %.c
	@printf "Compiling %s\n" "$<"

	@$(MKDIR_P) $(@D)

ifeq ($(EXPORT_COMPILE_COMMANDS),yes)
	$(CC) -c $< -o $(BUILD_DIR)/$*.o $(CFLAGS) -MJ $(BUILD_DIR)/$*.compile_commands.json
else
	$(CC) -c $< -o $(BUILD_DIR)/$*.o $(CFLAGS)
endif

$(BUILD_DIR)/%.o $(BUILD_DIR)/%.compile_commands.json: %.cpp
	@printf "Compiling %s\n" "$<"

	@$(MKDIR_P) $(@D)

ifeq ($(EXPORT_COMPILE_COMMANDS),yes)
	$(CXX) -c $< -o $(BUILD_DIR)/$*.o $(CXXFLAGS) -MJ $(BUILD_DIR)/$*.compile_commands.json
else
	$(CXX) -c $< -o $(BUILD_DIR)/$*.o $(CXXFLAGS)
endif

# usage:
#   make watch
#   make watch COMMAND=build
#
# Passing no `COMMAND` runs `make` with no target, which implies the target `all` (as the first target in the Makefile)
watch:
	PID=;	\
	while true; do \
		clear;	\
		$(MAKE) -sj $(COMMAND);	\
		RESULT=$$?;	\
		if [[ "$$PID" != "" ]]; then \
			kill $$PID;	\
			PID="";	\
		fi; \
		if [[ $$RESULT -eq 0 ]]; then \
			./$(BUILD_DIR)/$(EXE) &	\
			PID=$$!;	\
		fi; \
		inotifywait -qre close_write *;	\
	done
