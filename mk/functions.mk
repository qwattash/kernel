#
# Library functions for inclusion and utilities
#

##################################### utilities

#
# substitutes optional argument with given default if no argumen is given
# @param $1 optarg content
# @param $2 default
anrem-optarg = $(strip $(if $(strip $1),$1,$2))

#
# reverse a list
# @param $1 list to be reversed
#
define anrem-list-reverse = 
$(strip \
$(eval anrem-list-reverse-out := $(NULL))\
$(foreach anrem-list-reverse-item,$1,\
	$(eval anrem-list-reverse-out := $(strip $(anrem-list-reverse-item) $(anrem-list-reverse-out)))\
)\
$(anrem-list-reverse-out)\
)
endef

##################################### modules handling

#
# include given modules, this function MUST be used to include
# the project modules
# at the end the variable is set to a known value indicating that
# inclusion have finished
# @param $1 list of modules to be included
define anrem-include-modules = 
$(foreach ANREM_CURRENT_MODULE,$(1),\
	$(eval -include $(word 1,$(wildcard $(ANREM_CURRENT_MODULE)/*.mk)))\
)\
$(eval ANREM_CURRENT_MODULE := $(ANREM_MODULE_END))
endef

#
# retrieve the current path of the module
# useful for defining module targets
anrem-current-path = $(ANREM_CURRENT_MODULE)

#
# export path of the module to the global variable MOD_<module_name>
# this is useful when compiling and linking object files and .h from
# other modules which may move in the code tree
# This function allows flawless refactoring capabilities at
# package granularity with absolutely no change in the makefiles as long
# as the file names and final module names are not changed.
# As an extension to limit the effect of a changing module name it can be passed
# the name to use as argument to this function.
# This function is equivalent to is $MOD_mymodule := $(call anrem-current-path)
# when no name clashes occur
# @param $1 module path
# @param $2 optional name of the module to use
#

# comments can not be done inside the define so deal with it!
# Instead I'll give pseudocode, you're welcome..
# void anrem-def-modx(path, [custom_name=NULL]):
# if (not path in EXPORTED_MODULES):
# 	// if no custom name is given, use the module directory name
# 	// otherwise use the given custom name
#	if (custom_name == NULL):
#		words = split('/', path)
#		name = words.last()
# 	else:
# 		name = custom_name
#	// module not yet exported, try to create MOD variable
# 	if (name in MOD_VAR_NAMES):
#		//conflicting module
#		rename old conflicting module MOD var to a longer name
#		use longer name to create MOD var for the current module
#		set the value for the new module var
#		add new module var name to MOD_VAR_NAMES
#		add path to EXPORTED_MODULES
#	else:
#		// new module, create MOD variable normally
#		create MOD var using just the module name
#		add new module var name to MOD_VAR_NAMES
#		add path to EXPORTED_MODULES
# 
# Secondly get the name of the module into a variable used locally
# Then check again for the name of the module inside the exported paths
# if the name is found, this is a problem! Notify the user with a warning and rename both modules' MOD_x var
# by appending the 
# else everything ok, export the MOD_x var as normal
define anrem-mod-var =
$(if $(filter $1,$(EXPORTED_MODULES)),,\
	$(eval anrem-def-mod-var-name := $(call anrem-optarg,$(strip $2),$(subst $(dir $1),,$1)))\
	$(eval EXPORTED_MODULES += $1)\
	$(if $(filter $(anrem-def-mod-var-name),$(MOD_VAR_NAMES)),\
		$(eval anrem-def-mod-var-duplicate := $(MOD_$(anrem-def-mod-var-name)))\
		$(warning Found modules with same name: $(strip $1), $(anrem-def-mod-var-duplicate).\
	 		Conflict has been resolved automatically,\
			however consider declaring module variables manually as shown in the docs.)\
		$(eval undefine MOD_$(anrem-def-mod-var-name))\
		$(eval MOD_VAR_NAMES := $(filter-out $(anrem-def-mod-var-name),$(MOD_VAR_NAMES)))\
		$(eval anrem-def-mod-var-duplicate-name := $(subst /,_,$(anrem-def-mod-var-duplicate)))\
		$(eval anrem-def-mod-var-name := $(subst /,_,$1))\
		$(eval MOD_$(anrem-def-mod-var-name) := $1)\
		$(eval MOD_$(anrem-def-mod-var-duplicate-name) := $(anrem-def-mod-var-duplicate))\
		$(eval MOD_VAR_NAMES += $(anrem-def-mod-var-name))\
		$(eval MOD_VAR_NAMES += $(anrem-def-mod-var-duplicate-name))\
	,\
		$(eval MOD_$(anrem-def-mod-var-name) := $1)\
		$(eval MOD_VAR_NAMES += $(anrem-def-mod-var-name))\
	)\
)
endef

#
# generate MOD_x variables for each module path in the given list
# the MOD variables are named in the following way:
# i) the module "*.mk" is named "module.mk" -> use automatic module name resolution (see anrem-def-mod-var)
# ii) the moduel "*.mk" is named starting with an underscore "_" (such as "_module.mk") the module is ignored
#	(see anrem-exclude-mod-var)
# iii) the module "*.mk" is named with some other name (such as "custom.mk") the module MOD variable will
#	be named after the "*.mk" name (in this case MOD_custom) provided that the name is not already in use
# @param $1 list of modules to inspect
#
define anrem-mod-export = 
$(foreach _MODULE,$(1),\
	$(eval anrem-mod-export-mk := $(subst $(SPACE),_,$(word 1,$(wildcard $(_MODULE)/*.mk))))\
	$(eval anrem-mod-export-name := $(subst $(dir $(anrem-mod-export-mk)),,$(basename $(anrem-mod-export-mk))))\
	$(if $(filter module,$(anrem-mod-export-name)),\
		$(call anrem-mod-var, $(_MODULE))\
	,\
		$(if $(filter _%,$(anrem-mod-export-name)),\
			$(call anrem-mod-exclude,$(_MODULE))\
		,\
			$(call anrem-mod-var, $(_MODULE), $(anrem-mod-export-name))\
		)\
	)\
)
endef


#
# exclude given module from MOD variable generation
# @param $1 module to be excluded
#
anrem-mod-exclude = $(eval EXPORTED_MODULES += $1)

##################################### target handling

#
# declare a target and add given it to the global targets list
# that is executed when make all is run
# @param $1 target
#
define anrem-build =
$(strip \
$(call anrem-target, $1)\
$(call anrem-build-list-add, $1)\
)
endef
#
# declare a clean target and add given target to the clean list
# that is executed whenever make clean is issued
# If the target name is omitted one is automatically generated
# @param $1 target
#
define anrem-clean = 
$(strip \
	$(call anrem-target, $(call anrem-optarg,$1,clean_$(call anrem-current-path)))\
	$(call anrem-clean-list-add, $(call anrem-optarg,$1,clean_$(call anrem-current-path)))\
)
endef

#
# add a target to the test targets list, the list is meant to hold
# targets used to build unit-tests or other testing code
# @param $1 the target to add to the list
#
define anrem-test = 
$(strip \
	$(call anrem-target, $(call anrem-optarg,$1,test_$(call anrem-current-path)))\
	$(call anrem-test-list-add, $(call anrem-optarg,$1,test_$(call anrem-current-path)))\
)
endef

#
# add target that cleans the automatic dependencies
# in <module>.deps, this also generates the target if not already present
# since the cleaning process is the same for all modules
#
define anrem-deps-clean =
$(strip \
	$(if $(filter deps_clean_$(call anrem-current-path),$(ANREM_DEPS_CLEAN)),,\
		$(eval ANREM_DEPS_CLEAN += deps_clean_$(call anrem-current-path))\
		$(eval $(call anrem-deps-clean-rule))
	)\
)
endef

#
# helper rule used in anrem-deps-clean
#
define anrem-deps-clean-rule =
deps_clean_$(call anrem-current-path):
	rm -rf $(call anrem-current-path)/$(ANREM_DEPS_DIR)
endef


#
# declare a target in the current module path.
# This does not add the target to any anrem target list.
# A target-local variable "path" is created to hold the path of the module
# inside the target.
# @param $1 target absolute name
#
anrem-target = $(strip $1)$(call anrem-target-def-var,$(strip $1), path,$(strip $(call anrem-current-path)))


#
# add given target to the build list 
# @param $1: target name
define anrem-build-list-add = 
$(eval ANREM_BUILD_TARGETS += $(strip $1))
endef
#
# add given target to the clean list 
# @param $1: target name
define anrem-clean-list-add =
$(eval ANREM_BUILD_CLEAN += $(strip $1))
endef

#
# add given target to the test list 
# @param $1: target name
define anrem-test-list-add =
$(eval ANREM_TEST_TARGETS += $(strip $1))
endef

############################################# target local variables

#
# define a target-local symbol for a given target and symbol name
# this generates something like:
# <target>: <symbol> := <value>
# @param $1: target for which the symbol is defined
# @param $2: symbol to be defined
# @param $3: value of the symbol
#
anrem-target-def-var = $(eval $1: $2 := $3)


############################################# path handling

#
# removes the last $1 subdirectories from a path
# e.g. anrem-path-tr, 2, my/fancy/path/to/something -> my/fancy/path
# @param $1 number of subdirs to remove from the string
# @param $2 path string
#
define anrem-path-cut = 
$(strip \
$(eval anrem-path-cut-pathlist := $(subst /,$(SPACE),$(strip $2)))\
$(eval anrem-path-cut-filter := $(wordlist 1,$1,$(anrem-path-cut-pathlist)))\
$(foreach anrem-path-cut-iter,$(anrem-path-cut-filter),\
	$(eval anrem-path-cut-pathlist := $(anrem-path-cut-pathlist)/)\
	$(eval anrem-path-cut-pathlist := $(patsubst %/,$(NULL),$(anrem-path-cut-pathlist)))\
)\
$(subst $(SPACE),/,$(strip $(anrem-path-cut-pathlist)))\
)
endef

############################################# local variables
# TODO fix when the variable is retrived from inside a rule

#
# Local variables utility, this can be used to declare and access
# local variables, this works inside the target rules too
# @param $1 symbol name
#
define anrem-local = 
$(strip $1_$(strip $(call anrem-local-get-suffix)))
endef

#
# Helper for anrem-local, gives the current path
# from both inside a target rule and outside.
define anrem-local-get-suffix =
$(if $(filter $(ANREM_MODULE_END),$(call anrem-current-path)),
	$(path),\
	$(call anrem-current-path)\
)
endef

#
# Local variables utility, store the given value in given local var
# @param $1 local symbol name
# @param $2 value to store
#
anrem-local-set = $(eval $(call anrem-local, $1) := $2)

#
# Local variables utility, get the value of a given local var
# @param $1 local symbol name
#
anrem-local-get = $($(call anrem-local, $1))

#
# join relative path with absolute path, safe usage outside make rules
# @param $1 module-relative path
# 
anrem-join = $(addprefix $(ANREM_CURRENT_MODULE)/,$(strip $(1)))


######################### automatic dependencies
#
# Many thanks to Tom Tromey <tromey@cygnus.com> who devised the method for GNU automake
# Also many thanks for reporting the method to Paul D. Smith <psmith@gnu.org> at
# mad-scientist.net/make/autodep.html
#
# WARNING: The automatic dependencies functionalities are gcc/g++ only
# in the future this may change
#

#
# Define an automatic target, in general an automatic target in ANREM is
# a target for which the dependencies are generated automatically by the
# system, based on the files included by the files involved in the rule.
#
# An automatic target is always restricted to the module in which it is defined,
# that is, automatic targets defined in a module A does not conflict with
# automatic targets in module B, even if they refer files with the same name
# (here name is referred to the name of the file, not the full path)
#
# There are 4 types of automatic targets in ANREM.
# i) module-global default automatic target:
#	has global scope inside the module and its rule is automatically determined
#	(using a default) in anrem, an example would be
#	<module_path>/%.o: <module_path>/%.c
#		$(CC) $(CFLAGS) -c -o $@ $<
# 
# ii) module-global automatic target:
#	has global scope inside the module and its rule is defined by the user (yes, you)
#	an example is:
#	<module_path>/%.o: <module_path>/%.c
#		$(CC) $(CFLAGS) -I $(MOD_includes) -c -o $@ $<
#	# assuming that the include flag is not in CFLAGS
#
# iii) target-specific automatic target:
#	basically it is an automatic target defined only for a group of user-defined targets
#	an example is:
#	$(custom_targets): <module_path>/%.o: <module_path>/%.c
#		$(CC) $(CFLAGS) -I $(MOD_includes) -c -o $@ $<
#	# assuming that the include flag is not in CFLAGS
#
# iv) target-specific default automatic target:
#	basically it is a default automatic target defined only for a group of user-defined targets,
#	its rule is automatically determined (using a default) in anrem, 
#	an example would be:
#	$(custom_targets): <module_path>/%.o: <module_path>/%.c
#		$(CC) $(CFLAGS) -c -o $@ $<
#
# You don't have to specify a rule in types (i) and (iv), while a rule declaration is expected
# for cases (ii) and (iii) after the invocation of this function
#
# The job of ANREM is making it easy for you to create those targets and not worry about
# the dependency files creation, deletion and updating.
# The creation of dependency files is parametrised using a call hook with the following
# signature:
# @param name: matched name in the rule (say %.o: %.c matches file.o, the argument value is "file.o")
# @param dependency_file: where the hook should store the dependency list
# @param source: source file(s) for which the hook should provide the dependencies
# anrem-hook-makedepend(name, dependency_file, source)
# The hook can be registered using the hook registration system as normal with type "anrem-hook-makedepend"
# or can be given directly at the time of declaration of the target/rule as an argument
#
# The method works by defining a chain pattern rule, suppressing the default target and
# making some .INTERMEDIATE the mkdeps relative to the scope of the pattern rule.
# While being somewhat cumbersome, the method has the advantage of being easy to manipulate both
# inside anrem and from the user point of view, who sees a pretty normal make-style target declaration.
#
# 
# $(call anrem-auto-target, bla) # notice no :
#	<rule cmds>
#
# Now you can define targets with automated deps handling just as any other
# ANREM target!
#

# @param [$1]: target pattern (e.g. %.o, which is the default)
# @param [$2]: source pattern (e.g. %.c, which is the default)
# @param [$3]: boolean, (True) generate default rule or (False) a custom one is given
# @param [$4]: scope of the rule, if NULL the scope is global else a target list must be given (see (iii) above)
# @param [$5]: hook function, if not given the global anrem-hook-makedepend is used
define anrem-auto-target =
$(eval -include $(wildcard $(call anrem-current-path)/$(ANREM_DEPS_DIR)/*.d))\
$(eval $(call anrem-def-mkdeps-target, \
	$(call anrem-optarg,$(strip $1),\%.o),\
	$(call anrem-optarg,$(strip $2),\%.c),\
	$5,\
	$4)\
)\
$(call anrem-def-auto-target-suppress-implicit, $1, $2)\
$(call anrem-deps-clean)\
$(if $(strip $3),\
	$(eval $(call anrem-def-default-target-rule, $1, $2, $4)),\
	$(call anrem-def-custom-target-rule, \
		$(call anrem-optarg,$(strip $1),\%.o),\
		$(call anrem-optarg,$(strip $2),\%.c),\
		$4\
	)\
)
endef

#
# suppress automatic target for the given pattern
# @param $1: target pattern
# @param $2: source pattern
define anrem-def-auto-target-suppress-implicit =
$(eval $(strip $1): $(strip $2))
endef


# rule that will be eval'ed to define the %.mkdeps chain target
# %.mkdeps: %.c
#	gcc -MM -MP -MT $*.o -MF $*.d $< # this is parametrized by the hook
#
# @param $1: target pattern
# @param $2: source pattern
# @param $3: the hook function to be used or NULL
# @param $4: the scope of the pattern rule
define anrem-def-mkdeps-target =
$(if $(strip $4),\
	.INTERMEDIATE: $(patsubst $(strip $1), %.mkdep, $(strip $4))\
)
$(call anrem-current-path)/%.mkdep: $(call anrem-current-path)/$(strip $2)
	@mkdir -p $(call anrem-current-path)/$(ANREM_DEPS_DIR)
	$(if $(strip $3),\
		$$(call $3, \
			$$(patsubst $(strip $2),$(strip $1),$$<),\
			$(call anrem-current-path)/$(ANREM_DEPS_DIR)/$$(lastword $$(subst /, ,$$*)).d,\
			$$<\
		),\
		$$(call anrem-hook-makedepend, \
			$$(patsubst $(strip $2),$(strip $1),$$<),\
			$(call anrem-current-path)/$(ANREM_DEPS_DIR)/$$(lastword $$(subst /, ,$$*)).d,\
			$$<\
		)\
	)
endef

# generate the default rule for the given pattern
# this uses a hook to enable the user to specify
# globally the default target for a pattern.
# Define the header like that
# [$(objects):] %.o: %.c %.mkdep
# @param $1: target pattern
# @param $2: source pattern
# @param $3: scope of the rule -> NULL or list of targets
define anrem-def-default-target-rule =
$(if $(strip $3), $(strip $3):) \
	$(call anrem-current-path)/$(strip $1): \
	$(call anrem-current-path)/$(strip $2) $(call anrem-current-path)/%.mkdep
	$(call anrem-hook-auto-target-rule, $(strip $1), $(strip $2))
endef

#
# Declare the rule header for the command to come from the user
#
# @param $1: target pattern
# @param $2: source pattern
# @param $3: scope of the rule -> NULL or list of targets
define anrem-def-custom-target-rule =
$(if $(strip $3), $(strip $3):) \
	$(call anrem-current-path)/$(strip $1): \
	$(call anrem-current-path)/$(strip $2) $(call anrem-current-path)/%.mkdep
endef

############################################### target groups

#
# Helper, resolve internal group name
# representation from the group name
# @param $1: group ID
define anrem-target-group-build-name =
__anrem_target_group_$(strip $1)
endef

#
# subscribe target to group
# @param $1: group ID
# @param $2: target list
define anrem-target-group-add = 
$(eval \
	$(call anrem-target-group-build-name, $1): $(strip $2)\
)\
$(eval GROUP_ITEMS_$(call anrem-target-group-build-name, $1) += $(strip $2))\
$(eval GROUP_MODULES_$(call anrem-target-group-build-name, $1) := \
	$(sort \
		$(GROUP_MODULES_$(call anrem-target-group-build-name, $1)) $(call anrem-current-path)\
	)\
)
endef

#
# get target group reference to be used
# as a dependency from the group
# @param $1: group ID
define anrem-target-group-depend =
$(eval .INTERMEDIATE: $(call anrem-target-group-build-name, $1))\
$(call anrem-target-group-build-name, $1)
endef

#
# get target group members
# @param $1: group ID
define anrem-target-group-members =
$(GROUP_ITEMS_$(call anrem-target-group-build-name, $1))
endef

#
# get modules that have members in the group
# this is useful to group header files and
# build -I flags
# @param $1: group ID
define anrem-target-group-modules =
$(GROUP_MODULES_$(call anrem-target-group-build-name, $1))
endef
