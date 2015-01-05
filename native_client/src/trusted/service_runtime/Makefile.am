AUTOMAKE_OPTIONS=subdir-objects

noinst_LTLIBRARIES = libserviceruntime.la

libserviceruntime_la_SOURCES = \
	nacl_app_thread.h \
	nacl_signal.h \
	nacl_resource.h \
	include/machine/_types.h \
	include/sys/fcntl.h \
	include/sys/nacl_name_service.h \
	include/sys/errno.h \
	include/sys/time.h \
	include/sys/stat.h \
	include/sys/dirent.h \
	include/bits/mman.h \
	include/bits/wordsize.h \
	include/bits/stat.h \
	sel_ldr.h \
	name_service/name_service.h \
	nacl_error_code.h \
	sel_mem.h \
	dyn_array.h \
	nacl_config.h \
	linux/nacl_syscall_inl.h \
	sel_rt.h \
	sel_util-inl.h \
	sel_memory.h \
	sel_addrspace.h \
	nacl_secure_service.h \
	sel_util.h \
	sel_ldr-inl.h \
	posix/sel_memory.c \
	nacl_kernel_service.h \
	arch/x86/sel_ldr_x86.h \
	arch/x86/nacl_ldt_x86.h \
	arch/x86/sel_rt.h \
	arch/x86_64/sel_rt_64.h \
	arch/x86_64/sel_ldr_x86_64.c \
	arch/x86_64/nacl_signal_64.h \
	arch/sel_ldr_arch.h

XX_CPPFLAGS = $(AM_CPPFLAGS) \
	   '-DNACL_LINUX=1' \
	   '-DNACL_ANDROID=0' \
	   '-DNACL_OSX=0' \
	   '-DNACL_WINDOWS=0' \
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

libserviceruntime_la_CPPFLAGS = $(XX_CPPFLAGS)
libserviceruntime_la_CFLAGS = $(XX_CFLAGS)
