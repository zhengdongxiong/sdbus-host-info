###
#	Include by the Makefile.include
###

# CMD define
#         echo_xxxx will be printed
#         cmd_xxxx will be executed
# ===========================================================================
echo_cmd = $(if $(echo_$(1)), echo "    $(echo_$(1))";)
cmd = $(Q)$(echo_cmd) $(cmd_$(1))

# Compile
# ===========================================================================
echo_cc = CC      $@
cmd_cc = $(CC) $(CFLAGS) $(cflags) \
	$(cflags_$(@F)) -c $< -o $@

# Linking
# ===========================================================================
echo_ld = LD      $@
cmd_ld = $(CC) $< -o $@ $(LDFLAGS) \
	$(ldflags) $(ldflags_$(@F))

# Linking multi file
# ===========================================================================
echo_ld_multi = LD      $@
cmd_ld_multi = $(CC) $^ -o $@ $(LDFLAGS) \
	$(ldflags) $(ldflags_$(@F)) #$(filter-out FORCE, $^)

define rule-multi
$(foreach m, $(notdir $1), \
	$(eval $(dst)/$m : \
	$(addprefix $(src)/, $($(m)-y))))
endef

# Compile libs
# ===========================================================================
echo_lib_obj = LD      $@
cmd_lib_obj = $(LD) -r $^ -o $@  #$(filter-out FORCE, $^)

# Archive
# ===========================================================================
echo_ar = AR      $@
cmd_ar = $(AR) rcs $@ $^ #$(filter-out FORCE, $^)

# Share library
# ===========================================================================
echo_shlib = LLD     $@
cmd_shlib = $(CC) -shared $^ -o $@ #$(filter-out FORCE, $^)

# BIN order
# ===========================================================================
echo_binorder = GEN     $@
cmd_binorder = echo '$@' >> $(binorder)

# Json
# ===========================================================================
clangd_json = compile_commands.json
clangd_json_py = scripts/genjs.py

echo_gencmd = GEN     $(addsuffix .cmd, $@)
cmd_gencmd = printf '$(addsuffix .cmd, $@) := $(cmd_cc)' > $(addsuffix .cmd, $@)

echo_genjs = GEN     $(clangd_json)
cmd_genjs = $(PYTHON) $(clangd_json_py)

# Clean
# ===========================================================================
clean_files := $(obj) $(deps) $(single) $(multi) \
		$(lib) $(curlib) $(arlib) $(shlib)

rmfiles := $(binorder) $(clangd_json) $(shell find . -name "*.o.cmd")
rmdir := .cache

cmd_cleanfiles = rm -rf $(clean_files)

echo_clean = CLEAN
cmd_clean = rm -rf $(rmfiles) $(rmdir)

# Install
# ===========================================================================
hdrinst := mkdir -p $(inst_path); cp -r $(hdr_dir) $(inst_path);
#libinst := mkdir -p $(inst_path)/$(lib_dir); cp -r $(wildcard $(lib_dir)/*.a) $(inst_path)/$(lib_dir);
bininst := mkdir -p $(inst_path)/bin; \
	   cat $(binorder) | xargs -i cp -r {} $(inst_path)/bin;

#link_lib    := $(addprefix $(inst_path)/, $(wildcard $(lib_dir)/*.so))
#shlib_ver   := $(addsuffix .$(version), $(link_lib))
#libinst := mkdir -p $(inst_path)/$(lib_dir); cp -r $(wildcard $(lib_dir)/*.a) $(inst_path)/$(lib_dir);
#libinst := mkdir -p $(inst_path)/$(lib_dir); \
#	   cp -r $(lib_dir)/*.a $(lib_dir)/*.so $(inst_path)/lib; \
#	   mv $(link_lib) $(shlib_ver); \
#	   ln -sf $(shlib_ver) $(link_lib);

echo_inst = INSTALL
cmd_inst = $(hdrinst) $(libinst) $(bininst)

# Uninstall
# ===========================================================================
uninst_path := $(inst_path)

echo_uninst = UNINSTALL
cmd_uninst = rm -rf $(uninst_path)
