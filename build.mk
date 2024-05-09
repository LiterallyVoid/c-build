# All objects.
OBJECTS = \
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

# Warnings.
WARNINGS ?= -Wall -Wextra -Wmissing-prototypes

# Optimization flags.
OPTFLAGS ?= -Og -g # -O3

# Flags that need to be used during both compilation and linking.
CODEGENFLAGS ?= -fsanitize=undefined -fsanitize=address

# All flags passed to the C compiler to compile object files.
CCFLAGS ?= -MMD

CCFLAGS += $(INCLUDES)
CCFLAGS += $(WARNINGS)
CCFLAGS += $(OPTFLAGS)
CCFLAGS += $(CODEGENFLAGS)

# Flags passed for C or C++ files, respectively.
CFLAGS ?=	$(CCFLAGS) -std=c2x
CXXFLAGS ?=	$(CCFLAGS)

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

	$(MKDIR_P) $(@D)
	$(CC) \
		-c $< -o $(BUILD_DIR)/$*.o \
		$(CFLAGS) \
		-MJ $(BUILD_DIR)/$*.compile_commands.json

$(BUILD_DIR)/%.o $(BUILD_DIR)/%.compile_commands.json: %.cpp
	@printf "Compiling %s\n" "$<"

	$(MKDIR_P) $(@D)
	$(CXX) \
		-c $< -o $(BUILD_DIR)/$*.o \
		$(CXXFLAGS) \
		-MJ $(BUILD_DIR)/$*.compile_commands.json

$(BUILD_DIR)/$(EXE): $(OBJECTS)
	@printf "Linking %s\n" "$@"
	$(CC) $^ -o $@ $(LDFLAGS)

$(BUILD_DIR)/compile_commands.json: $(OBJECTS:%.o=%.compile_commands.json)
	@printf "Exporting %s\n" "$@"
	( echo "["; cat $^; echo "]" ) > $@
