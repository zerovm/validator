define PREFIX_ERR

Please set up ZVM_PREFIX env variable to the desired installation path
Example: export ZVM_PREFIX=/opt/zerovm

endef
ifndef ZVM_PREFIX
$(error $(PREFIX_ERR))
endif

# We borrow heavily from the kernel build setup, though we are simpler since
# we don't have Kconfig tweaking settings on us.

# The implicit make rules have it looking for RCS files, among other things.
# We instead explicitly write all the rules we care about.
# It's even quicker (saves ~200ms) to pass -r on the command line.
MAKEFLAGS=-r

# The source directory tree.
srcdir := .
abs_srcdir := $(abspath $(srcdir))

# The name of the builddir.
builddir_name ?= out

# The V=1 flag on command line makes us verbosely print command lines.
ifdef V
  quiet=
else
  quiet=quiet_
endif

# Specify BUILDTYPE=Release on the command line for a release build.
BUILDTYPE ?= Release

# Directory all our build output goes into.
# Note that this must be two directories beneath src/ for unit tests to pass,
# as they reach into the src/ directory for data with relative paths.
builddir ?= $(builddir_name)/$(BUILDTYPE)
abs_builddir := $(abspath $(builddir))
depsdir := $(builddir)/.deps

# Object output directory.
obj := $(builddir)/obj
abs_obj := $(abspath $(obj))

# We build up a list of every single one of the targets so we can slurp in the
# generated dependency rule Makefiles in one pass.
all_deps :=



# C++ apps need to be linked with g++.
#
# Note: flock is used to seralize linking. Linking is a memory-intensive
# process so running parallel links can often lead to thrashing.  To disable
# the serialization, override LINK via an envrionment variable as follows:
#
#   export LINK=g++
#
# This will allow make to invoke N linker processes as specified in -jN.
LINK ?= flock $(builddir)/linker.lock $(CXX)

CC.target ?= $(CC)
CFLAGS.target ?= $(CFLAGS)
CXX.target ?= $(CXX)
CXXFLAGS.target ?= $(CXXFLAGS)
LINK.target ?= $(LINK)
LDFLAGS.target ?= $(LDFLAGS)
AR.target ?= $(AR)

# TODO(evan): move all cross-compilation logic to gyp-time so we don't need
# to replicate this environment fallback in make as well.
CC.host ?= gcc
CFLAGS.host ?=
CXX.host ?= g++
CXXFLAGS.host ?=
LINK.host ?= g++
LDFLAGS.host ?=
AR.host ?= ar

# Define a dir function that can handle spaces.
# http://www.gnu.org/software/make/manual/make.html#Syntax-of-Functions
# "leading spaces cannot appear in the text of the first argument as written.
# These characters can be put into the argument value by variable substitution."
empty :=
space := $(empty) $(empty)

# http://stackoverflow.com/questions/1189781/using-make-dir-or-notdir-on-a-path-with-spaces
replace_spaces = $(subst $(space),?,$1)
unreplace_spaces = $(subst ?,$(space),$1)
dirx = $(call unreplace_spaces,$(dir $(call replace_spaces,$1)))

# Flags to make gcc output dependency info.  Note that you need to be
# careful here to use the flags that ccache and distcc can understand.
# We write to a dep file on the side first and then rename at the end
# so we can't end up with a broken dep file.
depfile = $(depsdir)/$(call replace_spaces,$@).d
DEPFLAGS = -MMD -MF $(depfile).raw

# We have to fixup the deps output in a few ways.
# (1) the file output should mention the proper .o file.
# ccache or distcc lose the path to the target, so we convert a rule of
# the form:
#   foobar.o: DEP1 DEP2
# into
#   path/to/foobar.o: DEP1 DEP2
# (2) we want missing files not to cause us to fail to build.
# We want to rewrite
#   foobar.o: DEP1 DEP2 \
#               DEP3
# to
#   DEP1:
#   DEP2:
#   DEP3:
# so if the files are missing, they're just considered phony rules.
# We have to do some pretty insane escaping to get those backslashes
# and dollar signs past make, the shell, and sed at the same time.
# Doesn't work with spaces, but that's fine: .d files have spaces in
# their names replaced with other characters.
define fixup_dep
# The depfile may not exist if the input file didn't have any #includes.
touch $(depfile).raw
# Fixup path as in (1).
sed -e "s|^$(notdir $@)|$@|" $(depfile).raw >> $(depfile)
# Add extra rules as in (2).
# We remove slashes and replace spaces with new lines;
# remove blank lines;
# delete the first line and append a colon to the remaining lines.
sed -e 's|\\||' -e 'y| |\n|' $(depfile).raw |\
  grep -v '^$$'                             |\
  sed -e 1d -e 's|$$|:|'                     \
    >> $(depfile)
rm $(depfile).raw
endef

# Command definitions:
# - cmd_foo is the actual command to run;
# - quiet_cmd_foo is the brief-output summary of the command.

quiet_cmd_cc = CC($(TOOLSET)) $@
cmd_cc = $(CC.$(TOOLSET)) $(GYP_CFLAGS) $(DEPFLAGS) $(CFLAGS.$(TOOLSET)) -c -o $@ $<

quiet_cmd_cxx = CXX($(TOOLSET)) $@
cmd_cxx = $(CXX.$(TOOLSET)) $(GYP_CXXFLAGS) $(DEPFLAGS) $(CXXFLAGS.$(TOOLSET)) -c -o $@ $<

quiet_cmd_touch = TOUCH $@
cmd_touch = touch $@

quiet_cmd_copy = COPY $@
# send stderr to /dev/null to ignore messages when linking directories.
cmd_copy = ln -f "$<" "$@" 2>/dev/null || (rm -rf "$@" && cp -af "$<" "$@")

quiet_cmd_alink = AR($(TOOLSET)) $@
cmd_alink = rm -f $@ && $(AR.$(TOOLSET)) crs $@ $(filter %.o,$^)

quiet_cmd_alink_thin = AR($(TOOLSET)) $@
cmd_alink_thin = rm -f $@ && $(AR.$(TOOLSET)) crsT $@ $(filter %.o,$^)

# Due to circular dependencies between libraries :(, we wrap the
# special "figure out circular dependencies" flags around the entire
# input list during linking.
quiet_cmd_link = LINK($(TOOLSET)) $@
cmd_link = $(LINK.$(TOOLSET)) $(GYP_LDFLAGS) $(LDFLAGS.$(TOOLSET)) -o $@ -Wl,--start-group $(LD_INPUTS) -Wl,--end-group $(LIBS)

# We support two kinds of shared objects (.so):
# 1) shared_library, which is just bundling together many dependent libraries
# into a link line.
# 2) loadable_module, which is generating a module intended for dlopen().
#
# They differ only slightly:
# In the former case, we want to package all dependent code into the .so.
# In the latter case, we want to package just the API exposed by the
# outermost module.
# This means shared_library uses --whole-archive, while loadable_module doesn't.
# (Note that --whole-archive is incompatible with the --start-group used in
# normal linking.)

# Other shared-object link notes:
# - Set SONAME to the library filename so our binaries don't reference
# the local, absolute paths used on the link command-line.
quiet_cmd_solink = SOLINK($(TOOLSET)) $@
cmd_solink = $(LINK.$(TOOLSET)) -shared $(GYP_LDFLAGS) $(LDFLAGS.$(TOOLSET)) -Wl,-soname=$(@F) -o $@ -Wl,--whole-archive $(LD_INPUTS) -Wl,--no-whole-archive $(LIBS)

quiet_cmd_solink_module = SOLINK_MODULE($(TOOLSET)) $@
cmd_solink_module = $(LINK.$(TOOLSET)) -shared $(GYP_LDFLAGS) $(LDFLAGS.$(TOOLSET)) -Wl,-soname=$(@F) -o $@ -Wl,--start-group $(filter-out FORCE_DO_CMD, $^) -Wl,--end-group $(LIBS)


# Define an escape_quotes function to escape single quotes.
# This allows us to handle quotes properly as long as we always use
# use single quotes and escape_quotes.
escape_quotes = $(subst ','\'',$(1))
# This comment is here just to include a ' to unconfuse syntax highlighting.
# Define an escape_vars function to escape '$' variable syntax.
# This allows us to read/write command lines with shell variables (e.g.
# $LD_LIBRARY_PATH), without triggering make substitution.
escape_vars = $(subst $$,$$$$,$(1))
# Helper that expands to a shell command to echo a string exactly as it is in
# make. This uses printf instead of echo because printf's behaviour with respect
# to escape sequences is more portable than echo's across different shells
# (e.g., dash, bash).
exact_echo = printf '%s\n' '$(call escape_quotes,$(1))'

# Helper to compare the command we're about to run against the command
# we logged the last time we ran the command.  Produces an empty
# string (false) when the commands match.
# Tricky point: Make has no string-equality test function.
# The kernel uses the following, but it seems like it would have false
# positives, where one string reordered its arguments.
#   arg_check = $(strip $(filter-out $(cmd_$(1)), $(cmd_$@)) \
#                       $(filter-out $(cmd_$@), $(cmd_$(1))))
# We instead substitute each for the empty string into the other, and
# say they're equal if both substitutions produce the empty string.
# .d files contain ? instead of spaces, take that into account.
command_changed = $(or $(subst $(cmd_$(1)),,$(cmd_$(call replace_spaces,$@))),\
                       $(subst $(cmd_$(call replace_spaces,$@)),,$(cmd_$(1))))

# Helper that is non-empty when a prerequisite changes.
# Normally make does this implicitly, but we force rules to always run
# so we can check their command lines.
#   $? -- new prerequisites
#   $| -- order-only dependencies
prereq_changed = $(filter-out FORCE_DO_CMD,$(filter-out $|,$?))

# Helper that executes all postbuilds, and deletes the output file when done
# if any of the postbuilds failed.
define do_postbuilds
  @E=0;\
  for p in $(POSTBUILDS); do\
    eval $$p;\
    F=$$?;\
    if [ $$F -ne 0 ]; then\
      E=$$F;\
    fi;\
  done;\
  if [ $$E -ne 0 ]; then\
    rm -rf "$@";\
    exit $$E;\
  fi
endef

# do_cmd: run a command via the above cmd_foo names, if necessary.
# Should always run for a given target to handle command-line changes.
# Second argument, if non-zero, makes it do asm/C/C++ dependency munging.
# Third argument, if non-zero, makes it do POSTBUILDS processing.
# Note: We intentionally do NOT call dirx for depfile, since it contains ? for
# spaces already and dirx strips the ? characters.
define do_cmd
$(if $(or $(command_changed),$(prereq_changed)),
  @$(call exact_echo,  $($(quiet)cmd_$(1)))
  @mkdir -p "$(call dirx,$@)" "$(dir $(depfile))"
  $(if $(findstring flock,$(word 1,$(cmd_$1))),
    @$(cmd_$(1))
    @echo "  $(quiet_cmd_$(1)): Finished",
    @$(cmd_$(1))
  )
  @$(call exact_echo,$(call escape_vars,cmd_$(call replace_spaces,$@) := $(cmd_$(1)))) > $(depfile)
  @$(if $(2),$(fixup_dep))
  $(if $(and $(3), $(POSTBUILDS)),
    $(call do_postbuilds)
  )
)
endef

# Declare the "all" target first so it is the default,
# even though we don't have the deps yet.
.PHONY: all clean
all:

# make looks for ways to re-generate included makefiles, but in our case, we
# don't have a direct way. Explicitly telling make that it has nothing to do
# for them makes it go faster.
%.d: ;

# d'b
clean:
	rm -rf out

# Use FORCE_DO_CMD to force a target to run.  Should be coupled with
# do_cmd.
.PHONY: FORCE_DO_CMD
FORCE_DO_CMD:

TOOLSET := host
# Suffix rules, putting all outputs into $(obj).
$(obj).$(TOOLSET)/%.o: $(srcdir)/%.c FORCE_DO_CMD
	@$(call do_cmd,cc,1)
$(obj).$(TOOLSET)/%.o: $(srcdir)/%.cc FORCE_DO_CMD
	@$(call do_cmd,cxx,1)
$(obj).$(TOOLSET)/%.o: $(srcdir)/%.cpp FORCE_DO_CMD
	@$(call do_cmd,cxx,1)
$(obj).$(TOOLSET)/%.o: $(srcdir)/%.cxx FORCE_DO_CMD
	@$(call do_cmd,cxx,1)
$(obj).$(TOOLSET)/%.o: $(srcdir)/%.S FORCE_DO_CMD
	@$(call do_cmd,cc,1)
$(obj).$(TOOLSET)/%.o: $(srcdir)/%.s FORCE_DO_CMD
	@$(call do_cmd,cc,1)

# Try building from generated source, too.
$(obj).$(TOOLSET)/%.o: $(obj).$(TOOLSET)/%.c FORCE_DO_CMD
	@$(call do_cmd,cc,1)
$(obj).$(TOOLSET)/%.o: $(obj).$(TOOLSET)/%.cc FORCE_DO_CMD
	@$(call do_cmd,cxx,1)
$(obj).$(TOOLSET)/%.o: $(obj).$(TOOLSET)/%.cpp FORCE_DO_CMD
	@$(call do_cmd,cxx,1)
$(obj).$(TOOLSET)/%.o: $(obj).$(TOOLSET)/%.cxx FORCE_DO_CMD
	@$(call do_cmd,cxx,1)
$(obj).$(TOOLSET)/%.o: $(obj).$(TOOLSET)/%.S FORCE_DO_CMD
	@$(call do_cmd,cc,1)
$(obj).$(TOOLSET)/%.o: $(obj).$(TOOLSET)/%.s FORCE_DO_CMD
	@$(call do_cmd,cc,1)

$(obj).$(TOOLSET)/%.o: $(obj)/%.c FORCE_DO_CMD
	@$(call do_cmd,cc,1)
$(obj).$(TOOLSET)/%.o: $(obj)/%.cc FORCE_DO_CMD
	@$(call do_cmd,cxx,1)
$(obj).$(TOOLSET)/%.o: $(obj)/%.cpp FORCE_DO_CMD
	@$(call do_cmd,cxx,1)
$(obj).$(TOOLSET)/%.o: $(obj)/%.cxx FORCE_DO_CMD
	@$(call do_cmd,cxx,1)
$(obj).$(TOOLSET)/%.o: $(obj)/%.S FORCE_DO_CMD
	@$(call do_cmd,cc,1)
$(obj).$(TOOLSET)/%.o: $(obj)/%.s FORCE_DO_CMD
	@$(call do_cmd,cc,1)

TOOLSET := target
# Suffix rules, putting all outputs into $(obj).
$(obj).$(TOOLSET)/%.o: $(srcdir)/%.c FORCE_DO_CMD
	@$(call do_cmd,cc,1)
$(obj).$(TOOLSET)/%.o: $(srcdir)/%.cc FORCE_DO_CMD
	@$(call do_cmd,cxx,1)
$(obj).$(TOOLSET)/%.o: $(srcdir)/%.cpp FORCE_DO_CMD
	@$(call do_cmd,cxx,1)
$(obj).$(TOOLSET)/%.o: $(srcdir)/%.cxx FORCE_DO_CMD
	@$(call do_cmd,cxx,1)
$(obj).$(TOOLSET)/%.o: $(srcdir)/%.S FORCE_DO_CMD
	@$(call do_cmd,cc,1)
$(obj).$(TOOLSET)/%.o: $(srcdir)/%.s FORCE_DO_CMD
	@$(call do_cmd,cc,1)

# Try building from generated source, too.
$(obj).$(TOOLSET)/%.o: $(obj).$(TOOLSET)/%.c FORCE_DO_CMD
	@$(call do_cmd,cc,1)
$(obj).$(TOOLSET)/%.o: $(obj).$(TOOLSET)/%.cc FORCE_DO_CMD
	@$(call do_cmd,cxx,1)
$(obj).$(TOOLSET)/%.o: $(obj).$(TOOLSET)/%.cpp FORCE_DO_CMD
	@$(call do_cmd,cxx,1)
$(obj).$(TOOLSET)/%.o: $(obj).$(TOOLSET)/%.cxx FORCE_DO_CMD
	@$(call do_cmd,cxx,1)
$(obj).$(TOOLSET)/%.o: $(obj).$(TOOLSET)/%.S FORCE_DO_CMD
	@$(call do_cmd,cc,1)
$(obj).$(TOOLSET)/%.o: $(obj).$(TOOLSET)/%.s FORCE_DO_CMD
	@$(call do_cmd,cc,1)

$(obj).$(TOOLSET)/%.o: $(obj)/%.c FORCE_DO_CMD
	@$(call do_cmd,cc,1)
$(obj).$(TOOLSET)/%.o: $(obj)/%.cc FORCE_DO_CMD
	@$(call do_cmd,cxx,1)
$(obj).$(TOOLSET)/%.o: $(obj)/%.cpp FORCE_DO_CMD
	@$(call do_cmd,cxx,1)
$(obj).$(TOOLSET)/%.o: $(obj)/%.cxx FORCE_DO_CMD
	@$(call do_cmd,cxx,1)
$(obj).$(TOOLSET)/%.o: $(obj)/%.S FORCE_DO_CMD
	@$(call do_cmd,cc,1)
$(obj).$(TOOLSET)/%.o: $(obj)/%.s FORCE_DO_CMD
	@$(call do_cmd,cc,1)


ifeq ($(strip $(foreach prefix,$(NO_LOAD),\
    $(findstring $(join ^,$(prefix)),\
                 $(join ^,native_client/src/shared/gio/gio.target.mk)))),)
  include native_client/src/shared/gio/gio.target.mk
endif
ifeq ($(strip $(foreach prefix,$(NO_LOAD),\
    $(findstring $(join ^,$(prefix)),\
                 $(join ^,native_client/src/shared/gio/gio_lib.target.mk)))),)
  include native_client/src/shared/gio/gio_lib.target.mk
endif
ifeq ($(strip $(foreach prefix,$(NO_LOAD),\
    $(findstring $(join ^,$(prefix)),\
                 $(join ^,native_client/src/shared/platform/platform.target.mk)))),)
  include native_client/src/shared/platform/platform.target.mk
endif
ifeq ($(strip $(foreach prefix,$(NO_LOAD),\
    $(findstring $(join ^,$(prefix)),\
                 $(join ^,native_client/src/shared/platform/platform_lib.target.mk)))),)
  include native_client/src/shared/platform/platform_lib.target.mk
endif
ifeq ($(strip $(foreach prefix,$(NO_LOAD),\
    $(findstring $(join ^,$(prefix)),\
                 $(join ^,native_client/src/shared/platform/platform_tests.target.mk)))),)
  include native_client/src/shared/platform/platform_tests.target.mk
endif
ifeq ($(strip $(foreach prefix,$(NO_LOAD),\
    $(findstring $(join ^,$(prefix)),\
                 $(join ^,native_client/src/shared/utils/utils.target.mk)))),)
  include native_client/src/shared/utils/utils.target.mk
endif
ifeq ($(strip $(foreach prefix,$(NO_LOAD),\
    $(findstring $(join ^,$(prefix)),\
                 $(join ^,native_client/src/trusted/cpu_features/cpu_features.target.mk)))),)
  include native_client/src/trusted/cpu_features/cpu_features.target.mk
endif
ifeq ($(strip $(foreach prefix,$(NO_LOAD),\
    $(findstring $(join ^,$(prefix)),\
                 $(join ^,native_client/src/trusted/validator/ncfileutils_x86_64.target.mk)))),)
  include native_client/src/trusted/validator/ncfileutils_x86_64.target.mk
endif
ifeq ($(strip $(foreach prefix,$(NO_LOAD),\
    $(findstring $(join ^,$(prefix)),\
                 $(join ^,native_client/src/trusted/validator/validators.target.mk)))),)
  include native_client/src/trusted/validator/validators.target.mk
endif
ifeq ($(strip $(foreach prefix,$(NO_LOAD),\
    $(findstring $(join ^,$(prefix)),\
                 $(join ^,native_client/src/trusted/validator/x86/64/ncvalidate_verbose_x86_64.target.mk)))),)
  include native_client/src/trusted/validator/x86/64/ncvalidate_verbose_x86_64.target.mk
endif
ifeq ($(strip $(foreach prefix,$(NO_LOAD),\
    $(findstring $(join ^,$(prefix)),\
                 $(join ^,native_client/src/trusted/validator/x86/64/ncvalidate_x86_64.target.mk)))),)
  include native_client/src/trusted/validator/x86/64/ncvalidate_x86_64.target.mk
endif
ifeq ($(strip $(foreach prefix,$(NO_LOAD),\
    $(findstring $(join ^,$(prefix)),\
                 $(join ^,native_client/src/trusted/validator/x86/decoder/nc_decoder_x86_64.target.mk)))),)
  include native_client/src/trusted/validator/x86/decoder/nc_decoder_x86_64.target.mk
endif
ifeq ($(strip $(foreach prefix,$(NO_LOAD),\
    $(findstring $(join ^,$(prefix)),\
                 $(join ^,native_client/src/trusted/validator/x86/decoder/nc_opcode_modeling_verbose_x86_64.target.mk)))),)
  include native_client/src/trusted/validator/x86/decoder/nc_opcode_modeling_verbose_x86_64.target.mk
endif
ifeq ($(strip $(foreach prefix,$(NO_LOAD),\
    $(findstring $(join ^,$(prefix)),\
                 $(join ^,native_client/src/trusted/validator/x86/decoder/nc_opcode_modeling_x86_64.target.mk)))),)
  include native_client/src/trusted/validator/x86/decoder/nc_opcode_modeling_x86_64.target.mk
endif
ifeq ($(strip $(foreach prefix,$(NO_LOAD),\
    $(findstring $(join ^,$(prefix)),\
                 $(join ^,native_client/src/trusted/validator/x86/decoder/ncdis_decode_tables_x86_64.target.mk)))),)
  include native_client/src/trusted/validator/x86/decoder/ncdis_decode_tables_x86_64.target.mk
endif
ifeq ($(strip $(foreach prefix,$(NO_LOAD),\
    $(findstring $(join ^,$(prefix)),\
                 $(join ^,native_client/src/trusted/validator/x86/ncval_base_verbose_x86_64.target.mk)))),)
  include native_client/src/trusted/validator/x86/ncval_base_verbose_x86_64.target.mk
endif
ifeq ($(strip $(foreach prefix,$(NO_LOAD),\
    $(findstring $(join ^,$(prefix)),\
                 $(join ^,native_client/src/trusted/validator/x86/ncval_base_x86_64.target.mk)))),)
  include native_client/src/trusted/validator/x86/ncval_base_x86_64.target.mk
endif
ifeq ($(strip $(foreach prefix,$(NO_LOAD),\
    $(findstring $(join ^,$(prefix)),\
                 $(join ^,native_client/src/trusted/validator/x86/ncval_reg_sfi/ncval_reg_sfi_verbose_x86_64.target.mk)))),)
  include native_client/src/trusted/validator/x86/ncval_reg_sfi/ncval_reg_sfi_verbose_x86_64.target.mk
endif
ifeq ($(strip $(foreach prefix,$(NO_LOAD),\
    $(findstring $(join ^,$(prefix)),\
                 $(join ^,native_client/src/trusted/validator/x86/ncval_reg_sfi/ncval_reg_sfi_x86_64.target.mk)))),)
  include native_client/src/trusted/validator/x86/ncval_reg_sfi/ncval_reg_sfi_x86_64.target.mk
endif
ifeq ($(strip $(foreach prefix,$(NO_LOAD),\
    $(findstring $(join ^,$(prefix)),\
                 $(join ^,native_client/src/trusted/validator/x86/ncval_seg_sfi/ncdis_seg_sfi_verbose_x86_64.target.mk)))),)
  include native_client/src/trusted/validator/x86/ncval_seg_sfi/ncdis_seg_sfi_verbose_x86_64.target.mk
endif
ifeq ($(strip $(foreach prefix,$(NO_LOAD),\
    $(findstring $(join ^,$(prefix)),\
                 $(join ^,native_client/src/trusted/validator/x86/ncval_seg_sfi/ncdis_seg_sfi_x86_64.target.mk)))),)
  include native_client/src/trusted/validator/x86/ncval_seg_sfi/ncdis_seg_sfi_x86_64.target.mk
endif
ifeq ($(strip $(foreach prefix,$(NO_LOAD),\
    $(findstring $(join ^,$(prefix)),\
                 $(join ^,native_client/src/trusted/validator/x86/ncval_seg_sfi/ncval_seg_sfi_x86_64.target.mk)))),)
  include native_client/src/trusted/validator/x86/ncval_seg_sfi/ncval_seg_sfi_x86_64.target.mk
endif
ifeq ($(strip $(foreach prefix,$(NO_LOAD),\
    $(findstring $(join ^,$(prefix)),\
                 $(join ^,native_client/src/trusted/validator_x86/nccopy_x86_64.target.mk)))),)
  include native_client/src/trusted/validator_x86/nccopy_x86_64.target.mk
endif
ifeq ($(strip $(foreach prefix,$(NO_LOAD),\
    $(findstring $(join ^,$(prefix)),\
                 $(join ^,native_client/src/trusted/validator_x86/ncdis_util_x86_64.target.mk)))),)
  include native_client/src/trusted/validator_x86/ncdis_util_x86_64.target.mk
endif
ifeq ($(strip $(foreach prefix,$(NO_LOAD),\
    $(findstring $(join ^,$(prefix)),\
                 $(join ^,native_client/src/trusted/validator_x86/ncval_x86_64.target.mk)))),)
  include native_client/src/trusted/validator_x86/ncval_x86_64.target.mk
endif

.PHONY: validator install

validator: ncdis_util_x86_64 ncval_x86_64
	$(CC) -shared -o out/Release/libvalidator.so -Wl,-soname=$(ZVM_PREFIX)/libvalidator.so \
	out/Release/obj.target/platform/native_client/src/trusted/service_runtime/arch/x86_64/sel_ldr_x86_64.o \
	out/Release/obj.target/platform/native_client/src/trusted/service_runtime/posix/sel_memory.o \
	out/Release/obj.target/ncval_reg_sfi_x86_64/native_client/src/trusted/validator/x86/ncval_reg_sfi/address_sets.o \
	out/Release/obj.target/platform/native_client/src/shared/platform/posix/aligned_malloc.o \
	out/Release/obj.target/platform/native_client/src/shared/platform/posix/condition_variable.o \
	out/Release/obj.target/cpu_features/native_client/src/trusted/cpu_features/arch/x86/cpu_x86.o \
	out/Release/obj.target/cpu_features/native_client/src/trusted/cpu_features/arch/x86/cpu_xgetbv.o \
	out/Release/obj.target/ncval_base_x86_64/native_client/src/trusted/validator/x86/error_reporter.o \
	out/Release/obj.target/ncval_base_verbose_x86_64/native_client/src/trusted/validator/x86/error_reporter_verbose.o \
	out/Release/obj.target/utils/native_client/src/shared/utils/flags.o \
	out/Release/obj.target/utils/native_client/src/shared/utils/formatting.o \
	out/Release/obj.target/gio/native_client/src/shared/gio/gio.o \
	out/Release/obj.target/gio/native_client/src/shared/gio/gio_mem.o \
	out/Release/obj.target/gio/native_client/src/shared/gio/gio_mem_snapshot.o \
	out/Release/obj.target/gio/native_client/src/shared/gio/gio_pio.o \
	out/Release/obj.target/gio/native_client/src/shared/gio/gprintf.o \
	out/Release/obj.target/ncval_base_x86_64/native_client/src/trusted/validator/x86/halt_trim.o \
	out/Release/obj.target/platform/native_client/src/shared/platform/posix/lock.o \
	out/Release/obj.target/platform/native_client/src/shared/platform/nacl_check.o \
	out/Release/obj.target/platform/native_client/src/shared/platform/linux/nacl_clock.o \
	out/Release/obj.target/platform/native_client/src/shared/platform/posix/nacl_exit.o \
	out/Release/obj.target/platform/native_client/src/shared/platform/posix/nacl_fast_mutex.o \
	out/Release/obj.target/platform/native_client/src/shared/platform/posix/nacl_find_addrsp.o \
	out/Release/obj.target/platform/native_client/src/shared/platform/nacl_global_secure_random.o \
	out/Release/obj.target/platform/native_client/src/shared/platform/posix/nacl_host_desc.o \
	out/Release/obj.target/platform/native_client/src/shared/platform/nacl_host_desc_common.o \
	out/Release/obj.target/platform/native_client/src/shared/platform/linux/nacl_host_dir.o \
	out/Release/obj.target/platform/native_client/src/shared/platform/nacl_interruptible_condvar.o \
	out/Release/obj.target/platform/native_client/src/shared/platform/nacl_interruptible_mutex.o \
	out/Release/obj.target/platform/native_client/src/shared/platform/nacl_log.o \
	out/Release/obj.target/platform/native_client/src/shared/platform/posix/nacl_secure_random.o \
	out/Release/obj.target/platform/native_client/src/shared/platform/nacl_secure_random_common.o \
	out/Release/obj.target/platform/native_client/src/shared/platform/nacl_sync_checked.o \
	out/Release/obj.target/platform/native_client/src/shared/platform/posix/nacl_thread_id.o \
	out/Release/obj.target/platform/native_client/src/shared/platform/posix/nacl_time.o \
	out/Release/obj.target/platform/native_client/src/shared/platform/posix/nacl_timestamp.o \
	out/Release/obj.target/platform/native_client/src/shared/platform/nacl_time_common.o \
	out/Release/obj.target/nccopy_x86_64/native_client/src/trusted/validator_x86/nccopycode.o \
	out/Release/obj.target/nccopy_x86_64/native_client/src/trusted/validator_x86/nccopycode_stores.o \
	out/Release/obj.target/ncdis_seg_sfi_x86_64/native_client/src/trusted/validator/x86/ncval_seg_sfi/ncdecode.o \
	out/Release/obj.target/ncdis_seg_sfi_verbose_x86_64/native_client/src/trusted/validator/x86/ncval_seg_sfi/ncdecode_verbose.o \
	out/Release/obj.target/ncdis_decode_tables_x86_64/native_client/src/trusted/validator/x86/decoder/ncdis_decode_tables.o \
	out/Release/obj.target/ncdis_util_x86_64/native_client/src/trusted/validator_x86/ncdis_segments.o \
	out/Release/obj.target/ncdis_util_x86_64/native_client/src/trusted/validator_x86/ncenuminsts_x86_64.o \
	out/Release/obj.target/ncfileutils_x86_64/native_client/src/trusted/validator/ncfileutil.o \
	out/Release/obj.target/ncval_base_x86_64/native_client/src/trusted/validator/x86/ncinstbuffer.o \
	out/Release/obj.target/nc_opcode_modeling_x86_64/native_client/src/trusted/validator/x86/decoder/ncopcode_desc.o \
	out/Release/obj.target/nc_opcode_modeling_verbose_x86_64/native_client/src/trusted/validator/x86/decoder/ncopcode_desc_verbose.o \
	out/Release/obj.target/nc_decoder_x86_64/native_client/src/trusted/validator/x86/decoder/ncop_exps.o \
	out/Release/obj.target/ncval_seg_sfi_x86_64/native_client/src/trusted/validator/x86/ncval_seg_sfi/ncvalidate.o \
	out/Release/obj.target/ncvalidate_x86_64/native_client/src/trusted/validator/x86/64/ncvalidate.o \
	out/Release/obj.target/ncval_seg_sfi_x86_64/native_client/src/trusted/validator/x86/ncval_seg_sfi/ncvalidate_detailed.o \
	out/Release/obj.target/ncval_reg_sfi_x86_64/native_client/src/trusted/validator/x86/ncval_reg_sfi/ncvalidate_iter.o \
	out/Release/obj.target/ncval_reg_sfi_x86_64/native_client/src/trusted/validator/x86/ncval_reg_sfi/ncvalidate_iter_detailed.o \
	out/Release/obj.target/ncval_reg_sfi_verbose_x86_64/native_client/src/trusted/validator/x86/ncval_reg_sfi/ncvalidate_iter_verbose.o \
	out/Release/obj.target/ncval_reg_sfi_x86_64/native_client/src/trusted/validator/x86/ncval_reg_sfi/ncvalidate_utils.o \
	out/Release/obj.target/ncval_reg_sfi_x86_64/native_client/src/trusted/validator/x86/ncval_reg_sfi/ncval_decode_tables.o \
	out/Release/obj.target/ncval_reg_sfi_x86_64/native_client/src/trusted/validator/x86/ncval_reg_sfi/nc_cpu_checks.o \
	out/Release/obj.target/ncval_reg_sfi_x86_64/native_client/src/trusted/validator/x86/ncval_reg_sfi/nc_illegal.o \
	out/Release/obj.target/nc_decoder_x86_64/native_client/src/trusted/validator/x86/decoder/nc_inst_iter.o \
	out/Release/obj.target/nc_decoder_x86_64/native_client/src/trusted/validator/x86/decoder/nc_inst_state.o \
	out/Release/obj.target/nc_decoder_x86_64/native_client/src/trusted/validator/x86/decoder/nc_inst_trans.o \
	out/Release/obj.target/ncval_reg_sfi_x86_64/native_client/src/trusted/validator/x86/ncval_reg_sfi/nc_jumps.o \
	out/Release/obj.target/ncval_reg_sfi_x86_64/native_client/src/trusted/validator/x86/ncval_reg_sfi/nc_jumps_detailed.o \
	out/Release/obj.target/ncval_reg_sfi_x86_64/native_client/src/trusted/validator/x86/ncval_reg_sfi/nc_memory_protect.o \
	out/Release/obj.target/ncval_reg_sfi_x86_64/native_client/src/trusted/validator/x86/ncval_reg_sfi/nc_opcode_histogram.o \
	out/Release/obj.target/ncval_reg_sfi_x86_64/native_client/src/trusted/validator/x86/ncval_reg_sfi/nc_protect_base.o \
	out/Release/obj.target/ncdis_util_x86_64/native_client/src/trusted/validator_x86/nc_read_segment.o \
	out/Release/obj.target/ncval_base_x86_64/native_client/src/trusted/validator/x86/nc_segment.o \
	out/Release/obj.target/platform/native_client/src/shared/platform/platform_init.o \
	out/Release/obj.target/platform/native_client/src/shared/platform/refcount_base.o \
	out/Release/obj.target/ncval_base_x86_64/native_client/src/trusted/validator/x86/x86_insts.o \
	out/Release/obj.target/ncval_base_verbose_x86_64/native_client/src/trusted/validator/x86/x86_insts_verbose.o
	@mv $(obj).target/../ncval_x86_64 $(obj).target/../valz

install:
	install -m 775 out/Release/libvalidator.so $(ZVM_PREFIX)/libvalidator.so

quiet_cmd_regen_makefile = ACTION Regenerating $@
cmd_regen_makefile = ./native_client/build/gyp_nacl -fmake --ignore-environment "--toplevel-dir=." -Inative_client/build/configs.gypi -Inative_client/build/standalone_flags.gypi "--depth=." "-Dnacl_standalone=1" "-Dsysroot=native_client/toolchain/linux_arm-trusted" native_client/build/all.gyp
Makefile:
	$(call do_cmd,regen_makefile)

# "all" is a concatenation of the "all" targets from all the included
# sub-makefiles. This is just here to clarify.
all:

# Add in dependency-tracking rules.  $(all_deps) is the list of every single
# target in our tree. Only consider the ones with .d (dependency) info:
d_files := $(wildcard $(foreach f,$(all_deps),$(depsdir)/$(f).d))
ifneq ($(d_files),)
  include $(d_files)
endif
