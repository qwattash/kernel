#
# this is a template for a module makefile
# Note that at the current delelopment status the user should
# not rely on the order of inclusion of submodules
#
CURRENT := $(call anrem-current-path)

BUILD_TARGETS_$(CURRENT) := my_target1.o
BUILD_CLEAN_$(CURRENT) := my_clean

$(call anrem-target, my_target1.o): path := $(CURRENT)
$(call anrem-target, my_target1.o):
	echo "my_target1.o"
	touch $(path)/my_target1.o

$(call anrem-target, my_clean): path := $(CURRENT)
$(call anrem-target, my_clean):
	rm $(path)/*.o

$(call anrem-build, $(BUILD_TARGETS_$(CURRENT)))
$(call anrem-build-clean, $(BUILD_CLEAN_$(CURRENT)))
