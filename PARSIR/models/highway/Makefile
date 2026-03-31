# SPDX-FileCopyrightText: 2026 Andrea Mazzucchi <andrea.mazzucchi@tutamail.com>
# SPDX-FileCopyrightText: 2026 Francesco Quaglia <francesco.quaglia@uniroma2.it>
#
# SPDX-License-Identifier: GPL-3.0-or-later

CC = gcc 
CFLAGS = -c -Wall -Wextra -Wpedantic -I../../include/ -I./ 
CHUNK_CKPT_FLAGS = -pie -fpie -I../../MVM_CHUNK/include -DSPECULATION
FULL_CKPT_FLAGS = -DSPECULATION
GRID_CKPT_FLAGS = -pie -fpie -I../../MVM_GRID_CKPT/include -DSPECULATION
TARGET = intermediate-highway.o 

SRCS = application.c 

all: 
	$(CC) $(SRCS) $(CFLAGS) -o $(TARGET)
	ld -r $(TARGET) --wrap=malloc --wrap=free -o highway.o

chunk_ckpt:
	$(CC) $(SRCS) $(CFLAGS) $(CHUNK_CKPT_FLAGS) -o $(TARGET)
	ld -r $(TARGET) --wrap=malloc --wrap=free -o highway.o

full_ckpt:
	$(CC) $(SRCS) $(CFLAGS) $(FULL_CKPT_FLAGS) -o $(TARGET)
	ld -r $(TARGET) --wrap=malloc --wrap=free -o highway.o

grid_ckpt:
	$(CC) $(SRCS) $(CFLAGS) $(GRID_CKPT_FLAGS) -o $(TARGET)
	ld -r $(TARGET) --wrap=malloc --wrap=free -o highway.o

clean:
	$(RM) *.o $(TARGET)
