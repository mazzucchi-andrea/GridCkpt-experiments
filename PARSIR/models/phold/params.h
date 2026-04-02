/*
 * SPDX-FileCopyrightText: 2026 Andrea Mazzucchi <andrea.mazzucchi@tutamail.com>
 * SPDX-FileCopyrightText: 2026 Francesco Quaglia <francesco.quaglia@uniroma2.it>
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

#ifndef M
#define M 1
#endif
#define CHUNKS_IN_LIST (8000)
#define REALLOCATION (CHUNKS_IN_LIST / 1000)
#define P (CHUNKS_IN_LIST >> 5)
#define TA (1)
