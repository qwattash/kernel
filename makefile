#
# Automated Non REcursive Make
# Author: qwattash (Alfredo Mazzinghi) <mzz.lrd@gmail.com>
#
# Main makefile for the project
# The ANREM system is aimed to provide an easy and extensible
# make environment for projects of any dimension with small deal
# of configuration.
# Non recursive make provides a way to avoid all the problems
# that recursion causes in make.
#

#global constants
ANREM_COMPONENTS := mk

#default target is all, needed because all has to be defined
#after all inclusions and otherwise the first included target
#would be run on a param-less make call
#.DEFAULT: all
predefined: all

#
# include environment
#
include $(ANREM_COMPONENTS)/env.mk

#
# ANREM hooks
#
include $(ANREM_COMPONENTS)/hooks.mk

#
# ANREM functions
#
include $(ANREM_COMPONENTS)/functions.mk

#
# ANREM function aliases
#
include $(ANREM_COMPONENTS)/alias.mk

#
# include top level project definition
#
include $(ANREM_TOP)/project.mk

#
# export MOD_x variables that
# relate a module name with its path
#
$(call anrem-mod-export,$(ANREM_MODULES))

#
# include project modules
#
$(call anrem-include-modules,$(ANREM_MODULES))

#
# include ANREM specific targets
#
include $(ANREM_COMPONENTS)/targets.mk
