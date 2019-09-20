# Make a symlink called `Makefile` in the top-level of the
# project which is linked to this file.
.DEFAULT_GOAL := all
builds        := .builds
build-current := .builds/current
stamp-file    := $(build-current)/last-build-stamp
cmake-utils   := $(dir $(realpath $(lastword $(MAKEFILE_LIST))))

-include $(build-current)/env-vars.mk

possible_targets := all run clean test

build-config := $(notdir $(realpath $(build-current)))
ifneq (,$(wildcard $(build-current)/Makefile))
    # Here we are invoking $(MAKE) directly instead of using
    # cmake because otherwise there seem to be issues with
    # propagating the jobserver.  For this same reason we
    # also do not just put the whole command into a variable
    # and just define the targets once.
    $(possible_targets): $(build-current)
	    @cd $(build-current) && $(MAKE) -s $@
	    @touch $(stamp-file)
else
    # Use cmake to build here because it is the preferred
    # way to go when it works for us (which it does in this
    # case).
    $(possible_targets): $(build-current)
	    @cd $(build-current) && cmake --build . --target $@
	    @touch $(stamp-file)
endif

clean-target := $(if $(wildcard $(builds)),clean,)

# Need to have `clean` as a dependency before removing the
# .builds folder because some outputs of the build are in the
# source tree and we need to clear them first.
distclean: $(clean-target)
	@rm -rf .builds

update:
	@git pull origin `git rev-parse --abbrev-ref HEAD` --quiet
	@git submodule update --init
	@cmc rc
	@bash $(cmake-utils)/outdated.sh -v
	@$(MAKE) -s all
	@$(MAKE) -s test

what:
	@scripts/outdated.sh

$(build-current):
	@cmc

.PHONY: $(possible_targets) update what