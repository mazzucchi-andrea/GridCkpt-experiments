#!/bin/bash

# --- Requirements Checking ---

required_commands=(gcc make bc awk gnuplot numactl)

for cmd in "${required_commands[@]}"
do
  if ! command -v "$cmd" &> /dev/null
  then
    echo "Error: $cmd could not be found."
    echo "Please install $cmd to run this script."
    exit 1
  fi
done

# Check for ImageMagick
if ! command -v convert &> /dev/null
then
  echo "Error: ImageMagick could not be found."
  echo "Please install ImageMagick to run this script."
  exit 1
fi

# --- Experiments Functions ---

run_kick() {
  echo "Running kick experiments..."
  cd Checkpoint
  taskset -c 0 ./kick_instr_cost.sh
  cd ..
  cd PARSIR
  ./kick_phold.sh
  ./kick_pcs.sh
  cd ..
}

run_instr_cost() {
  echo "Running instr_cost experiments..."
  cd Checkpoint
  taskset -c 0 ./instr_cost_exp.sh
  cd ..
  mkdir -p figures
  cp Checkpoint/plots/ckpt_comparison_size_1MB_grid_32_chunk_32_ops_1000.png figures/fig4.png
  cp Checkpoint/plots/ckpt_comparison_size_4MB_grid_256_chunk_256_ops_1000.png figures/fig5.png
}

run_phold() {
  echo "Running PHOLD experiments..."
  cd PARSIR
  ./phold.sh
  cd ..
  mkdir -p figures
  mv PARSIR/plots/phold/fig6.png figures/fig6.png
}

run_pcs() {
  echo "Running PCS experiments..."
  cd PARSIR
  ./pcs.sh
  cd ..
  mkdir -p figures
  mv PARSIR/pcs/phold/fig7.png figures/fig7.png
}

# --- Remove Artifacts ---

run_clean() {
  echo "Removing all artifacts produced..."
  rm -rf ./figures
  rm -rf ./Checkpoint/plots
  rm -f ./Checkpoint/MVM_CHUNK/chunk_repeat_test_results.csv
  rm -f ./Checkpoint/MVM_CHUNK/chunk_test_results.csv
  rm -f ./Checkpoint/MVM_GRID_CKPT/ckpt_repeat_test_results.csv
  rm -f ./Checkpoint/MVM_GRID_CKPT/ckpt_test_results.csv
  rm -rf ./PARSIR/plots
  rm -f ./PARSIR/phold.csv
  rm -f ./PARSIR/pcs.csv
}

# --- Main ---

if [ $# -eq 0 ]; then
  echo "No argument provided. Running ALL tests..."
  run_clean
  run_instr_cost
  run_phold
  run_pcs
else
  for arg in "$@"
  do
    case "$arg" in
      kick)
        run_kick
        ;;
      instr_cost)
        run_instr_cost
        ;;
      phold)
        run_phold
        ;;
      pcs)
        run_pcs
        ;;
      clean)
        run_clean
        ;;
      *)
        echo "Unknown test: $arg"
        echo "Valid options: kick, instr_cost, phold, pcs, clean"
        exit 1
        ;;
    esac
  done
fi