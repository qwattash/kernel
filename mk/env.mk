#
# Environment where the make process is carried on
#

# ------------------------------------ module inclusion lists and variables

# Top level directory
ANREM_TOP := $(shell pwd)

#list of modules to be traversed during the inclusion phase
#see http://perldoc.perl.org/perlre.html#Extended-Patterns
ANREM_MODULES := $(strip \
$(filter-out $(ANREM_COMPONENTS),\
	$(foreach _MODULE, $(shell ls -Rl | grep -oP "(?<=^\.\/)[A-Za-z0-9\/_-]*(?=:$$)"),\
		$(if $(wildcard $(_MODULE)/*.mk), $(_MODULE))\
	)\
)\
)

# this is used to signal the end of module inclusion
ANREM_MODULE_END := __anrem_end_of_module_inclusion

# ----------------------------------- MOD variables lists

# stores names of MOD_<module_name> variables that have been exported so far
# this is used to detect and manage clashes in module vars naming
MOD_VAR_NAMES := $(NULL)

# this is used along MOD_VAR_NAMES to keep track of modules for which a MOD
# variable is defined
EXPORTED_MODULES := $(NULL)


# ---------------------------- target lists

#user defined targets list
ANREM_BUILD_TARGETS :=

#user defined debug targets
#TODO not yet implemented
DEBUG_TARGETS :=

#user defined clear list
ANREM_BUILD_CLEAN :=

# automatic dependencies clean list
ANREM_DEPS_CLEAN :=

#same as BUILD_CLEAN but for debug stuff
DEBUG_CLEAN :=

#user defined test targets list
ANREM_TEST_TARGETS :=

# ------------------------------------ Auxiliary variables

# null variable useful for calling functions with null args
NULL :=

# space variable useful in some cases
SPACE := $(NULL) $(NULL)

# formatting helpers
define NEWLINE :=


endef

# Hi emacs user! Emacs makefile-mode will complain about the following
# lines, if you change this YOU are responsible for your misery.
# Don't say I didn't warn you.
define TAB :=
	
endef

# booleans
TRUE := T
FALSE := $(NULL)

# ------------------------------------- automatic dependencies

# name of the folder in the module where the automatic dependencies are stored
ANREM_DEPS_DIR := .deps
