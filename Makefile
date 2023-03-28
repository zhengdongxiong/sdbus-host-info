
PHONY := all
all :

# Global Makefile flags
# ===========================================================================
Q         := @
MAKEFLAGS += --no-print-directory
MAKEFLAGS += --no-builtin-rules
MAKEFLAGS += --no-builtin-variables

export Q

# Reserve
# Project name and Library name and Compile opts
# ===========================================================================
libname :=
version :=

export libname version

# All subdir
# ===========================================================================
hdr_dir   := include
lib_dir   := lib
src_dir   := source
inst_path := install
misc_dir  := samples
binorder  := bin.order

export hdr_dir lib_dir src_dir inst_path misc_dir binorder

# Define Global Compiler and Compile opts
# ===========================================================================
CC      = $(CROSS_COMPILE)gcc
LD      = $(CROSS_COMPILE)ld
AR      = $(CROSS_COMPILE)ar
CFLAGS  += -MMD -fPIC -I $(hdr_dir)/
LDFLAGS += -lsystemd -lpthread #-L $(lib_dir)/ -l$(libname)

PYTHON  := python

export CC LD AR CFLAGS LDFLAGS PYTHON

# Include Makefile.include
# ===========================================================================
include scripts/Makefile.include

# Make target
# ===========================================================================
build_bin := $(addprefix _build_, $(src_dir) $(misc_dir))
build_lib := $(addprefix _lib_, $(lib_dir))
clean_dir := $(addprefix _clean_, $(lib_dir) $(src_dir) $(misc_dir))
json_dir  := $(addprefix _genjs_, $(lib_dir) $(src_dir) $(misc_dir))

all: $(build_lib) $(build_bin)

clean: $(clean_dir)
	$(call cmd,clean)

genjs: $(json_dir)
	$(call cmd,genjs)

install:
	$(call cmd,inst)
uninstall:
	$(call cmd,uninst)

$(build_lib):
	$(Q)$(MAKE) $(build)=$(patsubst _lib_%,%,$@)

$(build_bin): $(build_lib)
	$(Q)$(MAKE) $(build)=$(patsubst _build_%,%,$@)

$(clean_dir):
	$(Q)$(MAKE) $(clean)=$(patsubst _clean_%,%,$@)

$(json_dir):
	$(Q)$(MAKE) $(genjs)=$(patsubst _genjs_%,%,$@)

#$(bin_inst):
#	$(Q)$(MAKE) $(bininst)=$(patsubst _bininst_%,%,$@)

help:
	@echo "Build:"
	@echo "	all		- Build all code (default)"
	@echo "Clean:"
	@echo "	clean		- Remove most generated files"
	@echo "Generated:"
	@echo "	genjs		- Generated compile_commands.json"

FORCE:

PHONY += clean genjs install uninstall help FORCE
PHONY += $(build_bin) $(build_lib) $(clean_dir) $(json_dir)

.PHONY: $(PHONY)
