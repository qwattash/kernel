#
# Environment where the make process is carried on
#

# Top level directory
ANREM_TOP := $(shell pwd)

#list of modules to be traversed during the inclusion phase
#see http://perldoc.perl.org/perlre.html#Extended-Patterns
ANREM_MODULES := $(filter-out $(ANREM_COMPONENTS), $(shell ls -Rl | grep -oP "(?<=^\.\/)[A-Za-z0-9\/_-]*(?=:$$)"))

#user defined targets list
ANREM_BUILD_TARGETS :=

#user defined debug targets
#TODO not yet implemented
DEBUG_TARGETS :=

#user defined clear list
ANREM_BUILD_CLEAN :=

#same as BUILD_CLEAN but for debug stuff
DEBUG_CLEAN :=
