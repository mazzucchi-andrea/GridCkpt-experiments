#!/usr/bin/env bash
set -euo pipefail

LOOKAHEAD=(0.25 0.5 1.0)

# Detect total CPU threads and compute 25%, 50%, 100%
TOTAL_THREADS=$(nproc)
T25=$(( TOTAL_THREADS / 4 ))
T50=$(( TOTAL_THREADS / 2 ))
# Ensure minimums of 1
[[ $T25 -lt 1 ]] && T25=1
[[ $T50 -lt 1 ]] && T50=1
THREADS=($T25 $T50 $TOTAL_THREADS)

RUN=5
WARMUP=10
DURATION=60

OBJECTS=(1024)
M=(1 100)

SIM=./bin/PARSIR-simulator

parse_output() {
awk '
/^SPEC_WINDOWS:/ {sw=$2}
/^ROLLBACKS:/ {rb=$2}
/^TOTAL_EVENTS:/ {te=$2}
/^COMMITTED_EVENTS:/ {ce=$2}
/^FILTERED_EVENTS:/ {fe=$2}
END {printf "%s,%s,%s,%s,%s\n",sw,rb,te,ce,fe}'
}

format_params() {
    local out=()
    for kv in "$@"; do
        out+=("${kv#*=}")
    done
    IFS=,; echo "${out[*]}"
}

run_series() {
    local target=$1
    local csv=$2
    shift 2
    local args=("$@")

    echo "Compiling $target ${args[*]}"
    make -C build "$target" BENCHMARK=1 "${args[@]}" WARMUP=$WARMUP DURATION=$DURATION >/dev/null

    ckpt_type=${target#*_}

    for ((i=0;i<RUN;i++)); do
        echo "Run $((i+1))/$RUN : $target ${args[*]}"
        output=$($SIM)
        parsed=$(printf "%s\n" "$output" | parse_output)
        params=$(format_params "${args[@]}")
        echo "$ckpt_type,$params,$parsed" >> "$csv"
    done
}

echo "CKPT_TYPE,THREADS,SPEC_WINDOW,OBJECTS,M,SPEC_WINDOWS,ROLLBACKS,TOTAL_EVENTS,COMMITTED_EVENTS,FILTERED_EVENTS" > phold.csv

for t in "${THREADS[@]}"; do
for l in "${LOOKAHEAD[@]}"; do
for o in "${OBJECTS[@]}"; do
for m in "${M[@]}"; do
    run_series phold_grid_ckpt phold.csv THREADS=$t LOOKAHEAD=$l OBJECTS=$o M=$m
    run_series phold_chunk_ckpt phold.csv THREADS=$t LOOKAHEAD=$l OBJECTS=$o M=$m
    run_series phold_full_ckpt phold.csv THREADS=$t LOOKAHEAD=$l OBJECTS=$o M=$m
done
done
done
done

rm -rf plots/phold
mkdir -p plots/phold

gcc -O3 get_phold_data.c -o get_phold_data -lm
for l in "${LOOKAHEAD[@]}"; do
for o in "${OBJECTS[@]}"; do
for m in "${M[@]}"; do
for t in "${THREADS[@]}"; do
    ./get_phold_data -r $RUN -t $t -s $l -o $o -m $m
done 
    gnuplot -c plot_phold.gp $m $l
    rm phold_plot_data.csv;          
done
done
done

cd plots/phold
montage \
  throughput_obj1024_spec_windows0.25_m1.png \
  throughput_obj1024_spec_windows0.5_m1.png \
  throughput_obj1024_spec_windows1.0_m1.png \
  rollbacks_per_epoch_obj1024_spec_windows0.25_m1.png \
  rollbacks_per_epoch_obj1024_spec_windows0.5_m1.png \
  rollbacks_per_epoch_obj1024_spec_windows1.0_m1.png \
  throughput_obj1024_spec_windows0.25_m100.png \
  throughput_obj1024_spec_windows0.5_m100.png \
  throughput_obj1024_spec_windows1.0_m100.png \
  rollbacks_per_epoch_obj1024_spec_windows0.25_m100.png \
  rollbacks_per_epoch_obj1024_spec_windows0.5_m100.png \
  rollbacks_per_epoch_obj1024_spec_windows1.0_m100.png \
  -tile 3x4 -geometry +2+2 fig6.png

