AUTOMAKE_OPTIONS=subdir-objects

lib_LTLIBRARIES = libvalidator.la

libvalidator_la_SOURCES = \
	x86/ncval_reg_sfi/address_sets.c \
	x86/error_reporter.c \
	x86/error_reporter_verbose.c \
	x86/halt_trim.c \
	x86/ncval_seg_sfi/ncdecode.c \
	x86/ncval_seg_sfi/ncdecode_verbose.c \
	x86/decoder/ncdis_decode_tables.c \
	ncfileutil.c \
	x86/ncinstbuffer.c \
	x86/decoder/ncopcode_desc.c \
	x86/decoder/ncopcode_desc_verbose.c \
	x86/decoder/ncop_exps.c \
	x86/ncval_seg_sfi/ncvalidate.c \
	x86/64/ncvalidate.c \
	x86/ncval_seg_sfi/ncvalidate_detailed.c \
	x86/ncval_reg_sfi/ncvalidate_iter.c \
	x86/ncval_reg_sfi/ncvalidate_iter_detailed.c \
	x86/ncval_reg_sfi/ncvalidate_iter_verbose.c \
	x86/ncval_reg_sfi/ncvalidate_utils.c \
	x86/ncval_reg_sfi/ncval_decode_tables.c \
	x86/ncval_reg_sfi/nc_cpu_checks.c \
	x86/ncval_reg_sfi/nc_illegal.c \
	x86/decoder/nc_inst_iter.c \
	x86/decoder/nc_inst_state.c \
	x86/decoder/nc_inst_trans.c \
	x86/ncval_reg_sfi/nc_jumps.c \
	x86/ncval_reg_sfi/nc_jumps_detailed.c \
	x86/ncval_reg_sfi/nc_memory_protect.c \
	x86/ncval_reg_sfi/nc_opcode_histogram.c \
	x86/ncval_reg_sfi/nc_protect_base.c \
	x86/nc_segment.c \
	x86/x86_insts.c \
	x86/x86_insts_verbose.c \
	ncfileutil.h \
	types_memory_model.h \
	x86/ncval_seg_sfi/ncvalidate_internaltypes.h \
	x86/ncval_seg_sfi/ncdecode_verbose.h \
	x86/ncval_seg_sfi/ncdecode.h \
	x86/ncval_seg_sfi/ncvalidate_detailed.h \
	x86/ncval_seg_sfi/ncvalidate.h \
	x86/ncval_seg_sfi/ncdecode_aux.h \
	x86/ncval_seg_sfi/gen/ncdisasmtab_64.h \
	x86/ncval_seg_sfi/gen/ncbadprefixmask_64.h \
	x86/ncval_seg_sfi/gen/ncdecodetab_64.h \
	x86/nc_segment.h \
	x86/halt_trim.h \
	x86/nacl_regs64.h \
	x86/ncinstbuffer.h \
	x86/decoder/nc_inst_iter.h \
	x86/decoder/ncop_exps.h \
	x86/decoder/nc_inst_state.h \
	x86/decoder/generator/gen/nacl_disallows.h \
	x86/decoder/nc_inst_state_internal.h \
	x86/decoder/nc_inst_trans.h \
	x86/decoder/nc_decode_tables_types.h \
	x86/decoder/nc_decode_tables.h \
	x86/decoder/ncopcode_desc.h \
	x86/decoder/gen/ncop_expr_node_flag_impl.h \
	x86/decoder/gen/ncopcode_prefix.h \
	x86/decoder/gen/ncop_expr_node_kind_impl.h \
	x86/decoder/gen/nc_opcode_table_64.h \
	x86/decoder/gen/ncopcode_opcode_flags.h \
	x86/decoder/gen/nc_subregs_64.h \
	x86/decoder/gen/ncopcode_operand_flag_impl.h \
	x86/decoder/gen/ncopcode_prefix_impl.h \
	x86/decoder/gen/ncopcode_insts.h \
	x86/decoder/gen/ncopcode_operand_kind.h \
	x86/decoder/gen/ncopcode_operand_kind_impl.h \
	x86/decoder/gen/ncop_expr_node_flag.h \
	x86/decoder/gen/ncopcode_opcode_flags_impl.h \
	x86/decoder/gen/ncopcode_insts_impl.h \
	x86/decoder/gen/ncop_expr_node_kind.h \
	x86/decoder/gen/ncopcode_operand_flag.h \
	x86/decoder/gen/ncval_reg_sfi_opcode_table_64.h \
	x86/x86_insts.h \
	x86/nacl_regs.h \
	x86/error_reporter.h \
	x86/ncval_reg_sfi/ncvalidate_iter.h \
	x86/ncval_reg_sfi/ncvalidate_iter_detailed.h \
	x86/ncval_reg_sfi/nc_memory_protect.h \
	x86/ncval_reg_sfi/nc_cpu_checks.h \
	x86/ncval_reg_sfi/ncvalidate_utils.h \
	x86/ncval_reg_sfi/nc_opcode_histogram.h \
	x86/ncval_reg_sfi/nc_jumps.h \
	x86/ncval_reg_sfi/ncval_decode_tables.h \
	x86/ncval_reg_sfi/nc_jumps_detailed.h \
	x86/ncval_reg_sfi/nc_illegal.h \
	x86/ncval_reg_sfi/address_sets.h \
	x86/ncval_reg_sfi/ncvalidate_iter_internal.h \
	x86/ncval_reg_sfi/nc_protect_base.h \
	validation_cache.h \
	ncvalidate.h

EXTRA_DIST = x86/ncval_reg_sfi/address_sets_inl.c \
	x86/ncinstbuffer_inl.c \
	x86/x86_insts_inl.c \
	x86/ncinstbuffer_inl.c \
	x86/decoder/nc_inst_iter_inl.c \
	x86/decoder/ncopcode_desc_inl.c \
	x86/decoder/ncop_exps_inl.c \
	x86/decoder/nc_inst_state_statics.c

libvalidator_la_LIBADD = \
	../../shared/platform/libplatform.la \
	../../shared/utils/libutil.la \
	../../shared/gio/libgio.la \
	../validator_x86/libarchvalidator.la \
	../cpu_features/libcpufeatures.la \
	../service_runtime/libserviceruntime.la

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

libvalidator_la_CPPFLAGS = $(XX_CPPFLAGS)
libvalidator_la_CFLAGS=$(XX_CFLAGS)
libvalidator_la_LDFLAGS=$(AM_LDFLAGS) -lstdc++
