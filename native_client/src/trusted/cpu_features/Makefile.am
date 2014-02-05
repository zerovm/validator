noinst_LIBRARIES = libcpufeatures.a

libcpufeatures_a_SOURCES = \
	cpu_features.h \
	arch/x86/cpu_x86.h \
	arch/x86/cpu_x86.c \
	arch/x86/cpu_x86_features.h \
	arch/x86/cpu_xgetbv.S

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
	   '-DNDEBUG'

XX_CFLAGS = $(AM_CFLAGS) \
	 -Werror \
	 -pthread \
	 -fno-exceptions \
	 -Wall \
	 -fPIC \
	 -Wextra \
	 -Wno-long-long \
	 -Wswitch-enum \
	 -Wsign-compare \
	 -Wundef \
	 -fdiagnostics-show-option \
	 -m64 \
	 -fno-exceptions \
	 -Wall \
	 -O2 \
	 -fno-ident \
	 -fdata-sections \
	 -ffunction-sections

libcpufeatures_a_CPPFLAGS = $(XX_CPPFLAGS)
libcpufeatures_a_CFLAGS = $(XX_CFLAGS)
