# Required initializer
AC_PREREQ(2.59)
AC_INIT(validator, 0.9.0)

AC_CONFIG_AUX_DIR(config)
AC_CONFIG_MACRO_DIR(config)

AM_INIT_AUTOMAKE
AC_CONFIG_SRCDIR([native_client/src/trusted/validator/ncfileutil.c])
AC_CONFIG_HEADER([config.h])
m4_ifdef([AM_SILENT_RULES], [AM_SILENT_RULES([yes])])

# Checks for programs.
AC_PROG_CC
AC_PROG_CXX
AM_PROG_AS
AC_PROG_LIBTOOL
#PKG_PROG_PKG_CONFIG
AM_PROG_CC_C_O


AC_ARG_ENABLE(debug, [    --enable-debug                Enable debugging switches],
                       [ case "${enableval}" in
                         yes) CFLAGS="-O0 -g -Wall -fstack-protector-all";;
                         no) CFLAGS="-O2 -g -Wall -DNDEBUG";;
                         *) AC_MSG_ERROR(bad value ${enableval} for --enable-debug);;
                       esac ])

AC_ARG_ENABLE(efence, [    --enable-efence               Enable ElectricFence],
                       [ case "${enableval}" in
                         yes) LIBS="${LIBS} -lefence";;
                         no) ;;
                         *) AC_MSG_ERROR(bad value ${enableval} for --enable-debug);;
                       esac ])


case $host in
     *-darwin*)
       is_darwin=yes
       ;;
     *)
       is_unknown=yes
       ;;
esac

AM_CONDITIONAL(PLATFORM_DARWIN, test "x${is_darwin}" = xyes)
AM_CONDITIONAL(PLATFORM_UNKNOWN, test "x${is_unknown}" = xyes)

# Checks for libraries.
#CPPFLAGS="-O0"

# Checks for header files.
CPPFLAGS="$CPPFLAGS -std=c99 -D_GNU_SOURCE"

# Checks for typedefs, structures, and compiler characteristics.
AC_C_CONST

AC_SUBST(VERSION)

# Checks for library functions.
AC_CHECK_FUNCS([strcasecmp strspn strstr])

# Write config.status and the Makefile
AC_OUTPUT(Makefile native_client/src/Makefile \
                   native_client/src/shared/Makefile \
                   native_client/src/shared/utils/Makefile \
                   native_client/src/shared/gio/Makefile \
                   native_client/src/shared/platform/Makefile \
                   native_client/src/third_party/Makefile \
                   native_client/src/include/Makefile \
                   native_client/src/trusted/Makefile \
                   native_client/src/trusted/cpu_features/Makefile
                   native_client/src/trusted/service_runtime/Makefile
                   native_client/src/trusted/validator_x86/Makefile
                   native_client/src/trusted/validator/Makefile
                   test/Makefile
		   contrib/Makefile
		   contrib/validator.pc)
