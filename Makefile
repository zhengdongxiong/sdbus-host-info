
PHONY := all
all :

# Global Makefile flags
# ---------------------------------------------------------------------------
Q         := @
MAKEFLAGS += --no-print-directory
MAKEFLAGS += --no-builtin-rules
MAKEFLAGS += --no-builtin-variables

export Q

# Reserve
# Project name and Library name and Compile opts
# ---------------------------------------------------------------------------
libname     :=
version     :=
SHLIB_FLAGS :=
SHLIB_LIBS  :=

export libname version SHLIB_FLAGS SHLIB_LIBS

# All subdir
# ---------------------------------------------------------------------------
hdr_dir   := include
lib_dir   := #lib
src_dir   := source
inst_path := install
misc_dir  := samples

export hdr_dir lib_dir src_dir inst_path misc_dir

# Define Global Compiler and Compile opts
# ---------------------------------------------------------------------------
CC       = $(CROSS_COMPILE)gcc
LD       = $(CROSS_COMPILE)ld
AR       = $(CROSS_COMPILE)ar
CPPFLAGS += -I $(hdr_dir)/
CFLAGS   += -MMD -fPIC
LDFLAGS  += #-L $(lib_dir)/
LIBS     += -lsystemd -lpthread #-l$(libname)

export CC LD AR CPPFLAGS CFLAGS LDFLAGS LIBS

# Include Makefile include
# ---------------------------------------------------------------------------
include scripts/Makefile.include

# Make target
# ---------------------------------------------------------------------------
build_bin  := $(addprefix _build_, $(src_dir) $(misc_dir))
build_lib  := $(addprefix _lib_, $(lib_dir))
clean_dir  := $(addprefix _clean_, $(lib_dir) $(src_dir) $(misc_dir))
hdr_inst   := $(addprefix _hdrinst_, $(hdr_dir))
lib_inst   := $(addprefix _libinst_, $(lib_dir))
bin_inst   := $(addprefix _bininst_, $(src_dir))
uninst_dir := $(addprefix _uninst_, $(inst_path))

all : $(build_lib) $(build_bin)

clean : $(clean_dir)

install : $(hdr_inst) $(lib_inst) $(bin_inst)

uninstall : $(uninst_dir)

$(build_lib) :
	$(Q)$(MAKE) $(build)=$(patsubst _lib_%,%,$@)

$(build_bin) : $(build_lib)
	$(Q)$(MAKE) $(build)=$(patsubst _build_%,%,$@)

$(clean_dir) :
	$(Q)$(MAKE) $(clean)=$(patsubst _clean_%,%,$@)

$(hdr_inst) :
	$(Q)$(MAKE) $(hdrinst)=$(patsubst _hdrinst_%,%,$@)

$(lib_inst) :
	$(Q)$(MAKE) $(libinst)=$(patsubst _libinst_%,%,$@)

$(bin_inst) :
	$(Q)$(MAKE) $(bininst)=$(patsubst _bininst_%,%,$@)

$(uninst_dir) :
	$(Q)$(MAKE) $(uninst)=$(patsubst _uninst_%,%,$@)

help :
	@echo "Build targets :"
	@echo "	all		- Build all code (default)"
	@echo ""
	@echo "Clean targets :"
	@echo "	clean		- Remove most generated files"

FORCE :

PHONY += prepare clean install uninstall help FORCE
PHONY += $(build_bin) $(clean_dir) $(hdr_inst) $(lib_inst) $(bin_inst) $(uninst_dir)

.PHONY : $(PHONY)
