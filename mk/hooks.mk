#
# This files defines the default hook functions used in anrem for
# parametrization of some tasks
# @Author: Alfredo Mazzinghi
#


# This hook is used by the automatic dependency system to build the
# dependency files that are then included in the main makefile
# anrem-hook-makedepend(name, dependency_file, source)
# @param $1: matched name in the rule (say %.o: %.c matches file.o, the argument value is "file")
# @param $2: where the hook should store the dependency list
# @param $3: source file(s) for which the hook should provide the dependencies
define anrem-hook-makedepend =
gcc -MM -MP -MT $1 -MF $2 $3
endef

# This hook is used by the automatic dependency system, it
# contains the default target rule for a given pattern.
# The result of the hook is $(eval)'ed so make sure that all
# rule variables are escaped properly.
# anrem-hook-auto-target-rule(target pattern, source pattern)
# @param $1: target pattern (i.e. %.o) 
# @param $2: source pattern (i.e. %.c)
define anrem-hook-auto-target-rule =
gcc -c -o $$@ $$<
endef
