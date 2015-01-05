AUTOMAKE_OPTIONS=subdir-objects

noinst_LTLIBRARIES = libplatform.la

libplatform_la_SOURCES = \
	nacl_interruptible_condvar.c \
	nacl_interruptible_mutex.c \
	platform_init.c \
	nacl_log.c \
	nacl_check.c \
	nacl_secure_random_common.c \
	linux/nacl_clock.c \
	linux/nacl_host_dir.c \
	nacl_sync_checked.c \
	nacl_global_secure_random.c \
	posix/nacl_secure_random.c \
	posix/nacl_thread_id.c \
	posix/nacl_timestamp.c \
	posix/condition_variable.c \
	posix/nacl_fast_mutex.c \
	posix/nacl_host_desc.c \
	posix/lock.c \
	posix/aligned_malloc.c \
	posix/nacl_time.c \
	posix/nacl_find_addrsp.c \
	posix/nacl_exit.c \
	nacl_host_desc_common.c \
	nacl_time_common.c \
	refcount_base.cc \
	nacl_check.h \
	nacl_secure_random_base.h \
	nacl_global_secure_random.h \
	refcount_base.h \
	nacl_log_intern.h \
	nacl_clock.h \
	nacl_sync.h \
	nacl_host_desc.h \
	nacl_sync_checked.h \
	nacl_timestamp.h \
	nacl_interruptible_mutex.h \
	linux/nacl_host_dir_types.h \
	nacl_log.h \
	nacl_threads.h \
	nacl_host_dir.h \
	nacl_find_addrsp.h \
	nacl_interruptible_condvar.h \
	nacl_exit.h \
	nacl_secure_random.h \
	aligned_malloc.h \
	nacl_time.h \
	posix/nacl_threads_types.h \
	posix/nacl_fast_mutex.h \
	posix/nacl_time_types.h \
	posix/nacl_secure_random_types.h \
	posix/nacl_host_desc_types.h

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

libplatform_la_CPPFLAGS = $(XX_CPPFLAGS)
libplatform_la_CFLAGS = $(XX_CFLAGS)
