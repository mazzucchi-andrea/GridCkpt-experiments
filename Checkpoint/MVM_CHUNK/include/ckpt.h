/*
 * SPDX-FileCopyrightText: 2026 Andrea Mazzucchi <andrea.mazzucchi@tutamail.com>
 * SPDX-FileCopyrightText: 2026 Francesco Quaglia <francesco.quaglia@uniroma2.it>
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

#ifndef _CKPT_
#define _CKPT_

#include <stdint.h>

#ifndef CHUNK
#define CHUNK 32
#endif

/* #if CHUNK != 32 || CHUNK != 64 || CHUNK != 128 || CHUNK != 256 || \ CHUNK !=
512 || CHUNK != 1024 || CHUNK != 2048 || CHUNK != 4096 #error "Valid Chunk Size
are 32, 64, 128, 256, 512, 1024, 2048 and 4096." #endif */

#ifndef ALLOCATOR_AREA_SIZE
#define ALLOCATOR_AREA_SIZE 0x100000
#endif

#define BITMAP_SIZE (ALLOCATOR_AREA_SIZE / CHUNK) / 8

void set_ckpt(uint8_t *);

void ckpt_chunk(uint8_t *);

void restore_chunks(uint8_t *);

#endif