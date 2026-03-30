#!/bin/bash

declare -a cache_flush=(0)
declare -a ops=(1000)
declare -a size=(0x100000)
declare -a mods=(32)
declare -a chunks=(32)
declare -a writes=(0.95 0.90 0.85 0.80 0.75 0.70 0.65 0.60 0.55 0.50 0.45 0.40 0.35 0.30)

# --- Helper ---
die() { echo "Error: $*" >&2; exit 1; }

# MVM_GRID_CKPT
cd MVM_GRID_CKPT || die "Failed to enter directory MVM_GRID_CKPT"
rm -f ckpt_test_results.csv ckpt_repeat_test_results.csv
echo "size,cache_flush,mod,ops,writes,reads,ckpt_time,ckpt_ci,restore_time,restore_ci" > ckpt_test_results.csv || die "Failed to create ckpt_test_results.csv"
echo "size,cache_flush,mod,ops,writes,reads,repetitions,ckpt_time,ckpt_ci,restore_time,restore_ci" > ckpt_repeat_test_results.csv || die "Failed to create ckpt_repeat_test_results.csv"

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
                    w_ops=$(echo "$o * $w" | bc) || die "bc failed computing w_ops (o=$o, w=$w)"
                    w_ops=${w_ops%.*}
                    r_ops=$(echo "$o - $w_ops" | bc) || die "bc failed computing r_ops (o=$o, w_ops=$w_ops)"
                    make ALLOCATOR_AREA_SIZE=$s WRITES=$w_ops READS=$r_ops CF=$cf MOD=$mod || die "make failed in MVM_GRID_CKPT (size=$s, writes=$w_ops, reads=$r_ops, cf=$cf, mod=$mod)"
                    ./application/prog || die "application/prog failed in MVM_GRID_CKPT (size=$s, writes=$w_ops, reads=$r_ops, cf=$cf, mod=$mod)"
                done
            done
        done
    done
done

make clean || echo "Warning: make clean failed in MVM_GRID_CKPT"
cd ..

# Tests with MVM chunk patch
cd MVM_CHUNK || die "Failed to enter directory MVM_CHUNK"
rm -f chunk_test_results.csv chunk_repeat_test_results.csv
echo "size,cache_flush,chunk,ops,writes,reads,ckpt_time,ckpt_ci,restore_time,restore_ci" > chunk_test_results.csv || die "Failed to create chunk_test_results.csv"
echo "size,cache_flush,chunk,ops,writes,reads,repetitions,ckpt_time,ckpt_ci,restore_time,restore_ci" > chunk_repeat_test_results.csv || die "Failed to create chunk_repeat_test_results.csv"

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
                    w_ops=$(echo "$o * $w" | bc) || die "bc failed computing w_ops (o=$o, w=$w)"
                    w_ops=${w_ops%.*}
                    r_ops=$(echo "$o - $w_ops" | bc) || die "bc failed computing r_ops (o=$o, w_ops=$w_ops)"
                    make ALLOCATOR_AREA_SIZE=$s WRITES=$w_ops READS=$r_ops CF=$cf CHUNK=$chunk || die "make failed in MVM_CHUNK (size=$s, writes=$w_ops, reads=$r_ops, cf=$cf, chunk=$chunk)"
                    ./application/prog || die "application/prog failed in MVM_CHUNK (size=$s, writes=$w_ops, reads=$r_ops, cf=$cf, chunk=$chunk)"
                done
            done
        done
    done
done

make clean || echo "Warning: make clean failed in MVM_CHUNK"
cd ..

rm -rf plots
mkdir plots || die "Failed to create plots directory"

gcc -O3 get_data.c -o get_plot_data || die "Failed to compile get_data.c"

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
                    ./get_plot_data $s $cf $mod $chunk $o || die "get_plot_data failed (size=$s, cf=$cf, mod=$mod, chunk=$chunk, ops=$o)"
                    gnuplot plot.gp || die "gnuplot failed (size=$s, cf=$cf, mod=$mod, chunk=$chunk, ops=$o)"
                done
            done
        done
    done
done

rm -f get_plot_data plot_data.csv
