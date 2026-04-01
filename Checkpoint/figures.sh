#!/bin/bash

# SPDX-FileCopyrightText: 2026 Andrea Mazzucchi <andrea.mazzucchi@tutamail.com>
# SPDX-FileCopyrightText: 2026 Francesco Quaglia <francesco.quaglia@uniroma2.it>
#
# SPDX-License-Identifier: GPL-3.0-or-later

declare -a cache_flush=(0)
declare -a ops=(1000)
declare -a size=(0x100000 0x400000)
declare -a mods=(32 256)
declare -a chunks=(32 256)
declare -a writes=(0.95 0.90 0.85 0.80 0.75 0.70 0.65 0.60 0.55 0.50 0.45 0.40 0.35 0.30)

rm -rf plots
mkdir plots

gcc -O3 get_data.c -o get_plot_data

for chunk in ${chunks[@]}
do
    for mod in ${mods[@]};
    do
        for s in ${size[@]};
        do
            for cf in ${cache_flush[@]};
            do
                for o in ${ops[@]}; 
                do
                    ./get_plot_data $s $cf $mod $chunk $o 
                    gnuplot plot.gp
                done
            done
        done
    done
done

rm -f get_plot_data
rm -f plot_data.csv