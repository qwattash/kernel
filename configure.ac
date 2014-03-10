#see also http://seul.org/docs/autotut/
##INIT section
#init package (see options)
AC_INIT([kernel], [0.1])
AC_PREREQ([2.59])
AC_CONFIG_AUX_DIR([config])
#init automake (see options)
AM_INIT_AUTOMAKE([-Wall foreign subdir-objects])
#define the header file where configuration defines are
AC_CONFIG_HEADER([configure.h])
##OPTIONS
##PROGRAMS checks
#determine C compile to use and set $(CC)
AC_PROG_CC
#test C compiler
AC_LANG_C
#determine ASM compiler
AC_PROG_AS
##LIBRARIES check which libraries can link
##HEADERS check for headers
#check stdc headers
AC_HEADER_STDC
##TYPEDEFS 
##FUNCTIONS check for functions in libs
#output configuration files such as Makefile.in
AC_CONFIG_FILES([Makefile])
##OUTPUT
AC_OUTPUT
