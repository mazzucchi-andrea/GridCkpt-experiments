#!/bin/bash

declare -a cache_flush=(0)
declare -a ops=(1000)
declare -a size=(0x100000 0x400000)
declare -a mods=(32 256)
declare -a chunks=(32 256)
declare -a writes=(0.95 0.90 0.85 0.80 0.75 0.70 0.65 0.60 0.55 0.50 0.45 0.40 0.35 0.30)

# --- Error Checking ---
if ! command -v bc &> /dev/null
then
    echo "Error: bc could not be found."
    echo "Please install bc to run this script."
    exit 1
fi

if ! command -v gnuplot &> /dev/null
then
    echo "Error: Gnuplot could not be found."
    echo "Please install gnuplot to run this script."
    exit 1
fi

if [ ! -f "plot.gp" ]; then
    echo "Error: Gnuplot template 'plot.gp' not found!"
    echo "Please make sure it's in the same directory as this script."
    exit 1
fi

# Tests with MVM_GRID_CKPT
cd MVM_GRID_CKPT
rm -f ckpt_test_results.csv
rm -f ckpt_repeat_test_results.csv
echo "size,cache_flush,mod,ops,writes,reads,ckpt_time,ckpt_ci,restore_time,restore_ci" > ckpt_test_results.csv
echo "size,cache_flush,mod,ops,writes,reads,repetitions,ckpt_time,ckpt_ci,restore_time,restore_ci" > ckpt_repeat_test_results.csv

for mod in ${mods[@]};
do
    for s in ${size[@]};
    do
        for cf in ${cache_flush[@]};
        do
            for o in ${ops[@]}; 
            do
                for w in ${writes[@]}; 
                do
                    w_ops=$(echo "$o * $w" | bc)
                    w_ops=${w_ops%.*}
                    r_ops=$(echo "$o - $w_ops" | bc)
                    make ALLOCATOR_AREA_SIZE=$s WRITES=$w_ops READS=$r_ops CF=$cf MOD=$mod
                    ./application/prog
                done
            done
        done
    done
done

make clean
cd ..

# Tests with MVM chunk patch
cd MVM_CHUNK
rm -f chunk_test_results.csv
rm -f chunk_repeat_test_results.csv
echo "size,cache_flush,chunk,ops,writes,reads,ckpt_time,ckpt_ci,restore_time,restore_ci" > chunk_test_results.csv
echo "size,cache_flush,chunk,ops,writes,reads,repetitions,ckpt_time,ckpt_ci,restore_time,restore_ci" > chunk_repeat_test_results.csv

for chunk in ${chunks[@]};
do
    for s in ${size[@]};
    do
        for cf in ${cache_flush[@]};
        do
            for o in ${ops[@]}; 
            do
                for w in ${writes[@]}; 
                do
                    w_ops=$(echo "$o * $w" | bc)
                    w_ops=${w_ops%.*}
                    r_ops=$(echo "$o - $w_ops" | bc)
                    make ALLOCATOR_AREA_SIZE=$s WRITES=$w_ops READS=$r_ops CF=$cf CHUNK=$chunk
                    ./application/prog
                done
            done
        done
    done
done

make clean
cd ..

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
