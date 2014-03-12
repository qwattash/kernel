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

#
# Utilities (not strictly related to inclusion stuff)
#

#
# return the sum of the values in the list
# @param $1 values list
#
sum = $(shell for ADDI in $(1); do SUM=$$(($$SUM + $$ADDI)); done; echo $$SUM;)  

#
# return file size in bytes
# @param $1 file absolute name
#
file-size = $(shell stat -c%s $(1))

#
# return a list containing the sizes in bytes of one or more files
# @param $1 file list
#
file-sizes-list = $(foreach FILE_ABS_NAME, $(1), $(call file-size, $(FILE_ABS_NAME)))

#
# return the sum of file sizes
# @param $1 file absolute names list
#
file-sizes-sum = $(call sum, $(call file-sizes-list, $(1)))

#
# return the number of $DDBLOCKSIZE blocks of padding needed to reach $VBOXMINSIZE 
# @param $1 sum of sector files sizes
#
padding-counter = $(shell if [ $(1) -lt $(VBOXMINSIZE) ]; then echo $$(( ($(VBOXMINSIZE) - $(1))/$(DDBLOCKSIZE) +1 )); else echo 0; fi;)

#
# return the count value needed for $(DD) execution
# @param $1 sector files absolute names list
#
dd-count = $(call padding-counter, $(call file-sizes-sum, $(1)))


