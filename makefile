#
# Main makefile
# the makefile architecture for this project has been built to
# avoid recursive makefiles which are bad.
# In order to achieve this, the make process has been split
# into modules, each module represent a logical entity
# in the kernel architecture and each module can have a number of
# submodules.
# The main makefile defines the building environmentand then
# delegates the specific handling
