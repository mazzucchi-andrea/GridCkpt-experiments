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
MIT=(0.4 0.1)

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

echo "CKPT_TYPE,THREADS,SPEC_WINDOW,OBJECTS,MIT,SPEC_WINDOWS,ROLLBACKS,TOTAL_EVENTS,COMMITTED_EVENTS,FILTERED_EVENTS" > pcs.csv

for t in "${THREADS[@]}"; do
for l in "${LOOKAHEAD[@]}"; do
for o in "${OBJECTS[@]}"; do
for ta in "${MIT[@]}"; do

    run_series pcs_grid_ckpt pcs.csv THREADS=$t LOOKAHEAD=$l OBJECTS=$o MIT=$ta
    run_series pcs_chunk_ckpt pcs.csv THREADS=$t LOOKAHEAD=$l OBJECTS=$o MIT=$ta
    run_series pcs_full_ckpt pcs.csv THREADS=$t LOOKAHEAD=$l OBJECTS=$o MIT=$ta

done
done
done
done

rm -rf plots/pcs
mkdir -p plots/pcs

gcc -O3 get_pcs_data.c -o get_pcs_data -lm
for l in "${LOOKAHEAD[@]}"; do
for o in "${OBJECTS[@]}"; do
for m in "${MIT[@]}"; do
for t in "${THREADS[@]}"; do
    ./get_pcs_data -r $RUN -t $t -s $l -o $o -m $m
done 
    gnuplot -c plot_pcs.gp $l $m
    rm pcs_plot_data.csv;          
done
done
done

cd plots/pcs
montage \
  throughput_mit_0.4_spec_window_0.25_obj1024.png \
  throughput_mit_0.4_spec_window_0.5_obj1024.png \
  throughput_mit_0.4_spec_window_1.0_obj1024.png \
  throughput_mit_0.1_spec_window_0.25_obj1024.png \
  throughput_mit_0.1_spec_window_0.5_obj1024.png \
  throughput_mit_0.1_spec_window_1.0_obj1024.png \
  -tile 3x2 -geometry +2+2 fig7.png

