#
# Library functions for inclusion and utilities
#

# include given modules, this function MUST be used to include
# the project modules
anrem-include-modules = $(foreach ANREM_CURRENT_MODULE,$(1),$(eval -include $(ANREM_CURRENT_MODULE)/module.mk))

#
# retrieve the current path of the module
# useful for defining module targets
anrem-current-path = $(ANREM_CURRENT_MODULE)

#
# add given target to the global targets list
# that is executed when make all is run
#
anrem-build = $(eval ANREM_BUILD_TARGETS += $(strip $(1)))

#
# add given target to the clean list
# that is executed whenever make clean is issued
#
anrem-clean = $(eval ANREM_BUILD_CLEAN += $(strip $(1)))

#
# define the local path for a given target
#
anrem-target-defpath = $(eval $(1): path:=$(ANREM_CURRENT_MODULE))

#
# define a target relative to current path
# @param $1 target absolute name
#
anrem-target = $(strip $(1))$(call anrem-target-defpath, $(strip $(1)))

#
# join relative path with absolute path, safe usage outside make rules
# 
anrem-join = $(addprefix $(ANREM_CURRENT_MODULE)/,$(strip $(1)))
