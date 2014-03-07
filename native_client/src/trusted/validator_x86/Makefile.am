AUTOMAKE_OPTIONS=subdir-objects

noinst_LTLIBRARIES = libarchvalidator.la

libarchvalidator_la_SOURCES = \
	nccopycode.c \
	nccopycode_stores.S \
	ncdis_segments.c \
	ncenuminsts_x86_64.c \
	nc_read_segment.c \
	ncdis_segments.h \
	ncenuminsts.h \
	nc_read_segment.h \
	ncdis_decode_tables.h

EXTRA_DIST = \
	ncstubout.c \
	ncval.c \
	ncdis_decode_tables.c

XX_CPPFLAGS = $(AM_CPPFLAGS) \
	   '-DNACL_LINUX=1' \
	   '-DNACL_ANDROID=0' \
	   '-DNACL_OSX=0' \
	   '-DNACL_WINDOWS=0' \
	   '-D_BSD_SOURCE=1' \
	   '-D_POSIX_C_SOURCE=199506' \
	   '-D_XOPEN_SOURCE=600' \
	   '-D_GNU_SOURCE=1' \
	   '-D__STDC_LIMIT_MACROS=1' \
	   '-D__STDC_FORMAT_MACROS' \
	   '-DNACL_TARGET_SUBARCH=64' \
	   '-DNACL_TARGET_ARCH=x86' \
	   '-DNACL_BUILD_SUBARCH=64' \
	   '-DNACL_BUILD_ARCH=x86' \
	   '-DNACL_TRUSTED_BUT_NOT_TCB' \
	   '-DNDEBUG'

XX_CFLAGS = $(AM_CFLAGS) \
	 -Werror \
	 -pthread \
	 -fno-exceptions \
	 -Wall \
	 -fPIC \
	 -Wno-long-long \
	 -Wundef \
	 -fdiagnostics-show-option \
	 -m64 \
	 -fno-exceptions \
	 -Wall \
	 -O2 \
	 -fno-ident \
	 -fdata-sections \
	 -ffunction-sections \
	 -Wstrict-prototypes \
	 -MMD \
	 -MF

libarchvalidator_la_CPPFLAGS = $(XX_CPPFLAGS)
libarchvalidator_la_CFLAGS = $(XX_CFLAGS)
