AUTOMAKE_OPTIONS=subdir-objects

bin_PROGRAMS = valz valzo
noinst_PROGRAMS = validator

validator_SOURCES = validate.c
valz_SOURCES = dyn_linked/ncval.c
valzo_SOURCES = dyn_linked/ncstubout.c


validator_LDADD = ../native_client/src/trusted/validator/libvalidator.la

XX_CPPFLAGS = $(AM_CPPFLAGS) \
	'-DNACL_LINUX=1' \
	'-D_BSD_SOURCE=1' \
           '-D_DEFAULT_SOURCE=1' \
	'-D_POSIX_C_SOURCE=199506' \
	'-D_XOPEN_SOURCE=600' \
	'-D_GNU_SOURCE=1' \
	'-D__STDC_LIMIT_MACROS=1' \
	'-D__STDC_FORMAT_MACROS' \
	'-DNACL_TARGET_SUBARCH=64' \
	'-DNACL_TARGET_ARCH=x86' \
	'-DNACL_BUILD_SUBARCH=64' \
	'-DNACL_BUILD_ARCH=x86' \
	'-DNACL_TRUSTED_BUT_NOT_TCB'


valz_CPPFLAGS = $(XX_CPPFLAGS)
valzo_CPPFLAGS = $(XX_CPPFLAGS)
validator_CPPFLAGS = $(XX_CPPFLAGS)

valz_LDADD = ../native_client/src/trusted/validator/libvalidator.la
valzo_LDADD = ../native_client/src/trusted/validator/libvalidator.la
