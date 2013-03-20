/*
 * Copyright (c) 2012 The Native Client Authors. All rights reserved.
 * Use of this source code is governed by a BSD-style license that can be
 * found in the LICENSE file.
 */
#include <stdio.h>
#include <string.h>

#define NACL_HALT_OPCODE 0xf4
void NaClFillMemoryRegionWithHalt(void *start, size_t size)
{
  memset(start, NACL_HALT_OPCODE, size);
}

