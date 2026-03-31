# SPDX-FileCopyrightText: 2026 Andrea Mazzucchi <andrea.mazzucchi@tutamail.com>
# SPDX-FileCopyrightText: 2026 Francesco Quaglia <francesco.quaglia@uniroma2.it>
#
# SPDX-License-Identifier: GPL-3.0-or-later

ALLOCATOR_AREA_SIZE=0x100000
WRITES=950
READS=50
MOD=64
CF=0

all:
	gcc -c prog.c -mavx -mavx2 -mavx512f -funroll-loops -pie -fPIE -I ../include -DALLOCATOR_AREA_SIZE=$(ALLOCATOR_AREA_SIZE) -DWRITES=$(WRITES) -DREADS=$(READS) -DMOD=$(MOD) -DCF=$(CF)