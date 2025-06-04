###
#	Include by the Makefile.include
###

# CMD define
#         quiet_xxxx will be printed
#         cmd_xxxx will be executed
# ===========================================================================
quiet_cmd = $(if $(quiet_$(1)), echo "    $(quiet_$(1))";)
      cmd = $(Q)$(quiet_cmd) $(cmd_$(1))
#quiet_cmd = $(if $($(quiet)cmd_$(1)), echo "    $($(quiet)cmd_$(1))";)
#      cmd = @$(quiet_cmd) $(cmd_$(1))

# Compile
# ===========================================================================
quiet_cc = CC      $@
  cmd_cc = $(CC) $(CFLAGS) $(cflags) \
	$(cflags_$(@F)) -c $< -o $@

# Linking
# ===========================================================================
quiet_ld = LD      $@
  cmd_ld = $(CC) $< -o $@ $(LDFLAGS) \
	$(ldflags) $(ldflags_$(@F))

# Linking multi file
# ===========================================================================
quiet_ld_multi = LD      $@
  cmd_ld_multi = $(CC) $^ -o $@ $(LDFLAGS) \
	$(ldflags) $(ldflags_$(@F)) #$(filter-out FORCE, $^)

define rule-multi
$(foreach m, $(notdir $1), \
	$(eval $(dst)/$m : \
	$(addprefix $(src)/, $($(m)-y))))
endef

# Compile libs
# ===========================================================================
quiet_lib_obj = LD      $@
  cmd_lib_obj = $(LD) -r $^ -o $@  #$(filter-out FORCE, $^)

# Archive
# ===========================================================================
quiet_arlib = AR      $@
  cmd_arlib = $(AR) rcs $@ $^ #$(filter-out FORCE, $^)

# Share library
# ===========================================================================
quiet_shlib = LLD     $@
  cmd_shlib = $(CC) -shared $^ -o $@ #$(filter-out FORCE, $^)

# bin.order
# ===========================================================================
cmd_binorder = { $(foreach m, $(order), \
	$(if $(filter %/$(binorder), $m), cat $m, echo $m);) :; } | awk '!x[$$0]++' - > $@

# Json
# ===========================================================================
clangd_json    := compile_commands.json
clangd_json_py := scripts/genjs.py

quiet_gencmd = GEN     $(addsuffix .cmd, $@)
  cmd_gencmd = printf '$(addsuffix .cmd, $@) := $(cmd_cc)' > $(addsuffix .cmd, $@)

quiet_genjs = GEN     $(clangd_json)
  cmd_genjs = python $(clangd_json_py)

# Clean
# ===========================================================================
clean_files := $(obj) $(deps) $(single) $(multi) \
	$(lib) $(curlib) $(arlib) $(shlib) $(order-file) $(deps:%.d=%.o.cmd)

rmfiles := .cache/ $(clangd_json)

cmd_cleanfiles = rm -rf $(clean_files)

quiet_rmfiles = CLEAN
  cmd_rmfiles = rm -rf $(rmfiles)

# Install
# ===========================================================================
hdrinst := mkdir -p $(inst_path); cp -r $(hdr_dir) $(inst_path);
#libinst := mkdir -p $(inst_path)/$(lib_dir); cp -r $(wildcard $(lib_dir)/*.a) $(inst_path)/$(lib_dir);
bininst := mkdir -p $(inst_path)/bin; \
	{ $(foreach m, $(bin_dir), cat $(m)/$(binorder);) :; } \
	| xargs -i cp -r {} $(inst_path)/bin;

#link_lib    := $(addprefix $(inst_path)/, $(wildcard $(lib_dir)/*.so))
#shlib_ver   := $(addsuffix .$(version), $(link_lib))
#libinst := mkdir -p $(inst_path)/$(lib_dir); cp -r $(wildcard $(lib_dir)/*.a) $(inst_path)/$(lib_dir);
#libinst := mkdir -p $(inst_path)/$(lib_dir); \
#	   cp -r $(lib_dir)/*.a $(lib_dir)/*.so $(inst_path)/lib; \
#	   mv $(link_lib) $(shlib_ver); \
#	   ln -sf $(shlib_ver) $(link_lib);

quiet_install = INSTALL
  cmd_install = $(hdrinst) $(libinst) $(bininst)

# Uninstall
# ===========================================================================
uninst_path := $(inst_path)

quiet_uninstall = UNINSTALL
  cmd_uninstall = rm -rf $(uninst_path)
