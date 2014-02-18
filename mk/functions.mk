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
anrem-build = $(eval ANREM_BUILD_TARGETS += $(addprefix $(ANREM_CURRENT_MODULE)/,$(strip $(1))))

#
# add given target to the clean list
# that is executed whenever make clean is issued
#
anrem-build-clean = $(eval ANREM_BUILD_CLEAN += $(addprefix $(ANREM_CURRENT_MODULE)/,$(strip $(1))))

#
# define a target relative to current path
#
anrem-target = $(addprefix $(ANREM_CURRENT_MODULE)/,$(1))
