#!/bin/bash

# SPDX-FileCopyrightText: 2026 Andrea Mazzucchi <andrea.mazzucchi@tutamail.com>
# SPDX-FileCopyrightText: 2026 Francesco Quaglia <francesco.quaglia@uniroma2.it>
#
# SPDX-License-Identifier: GPL-3.0-or-later

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
  ./figures.sh
  cd ..
  mkdir -p figures
  cp Checkpoint/plots/ckpt_comparison_size_1MB_grid_32_chunk_32_ops_1000.png figures/fig4.png
  cp Checkpoint/plots/ckpt_comparison_size_4MB_grid_256_chunk_256_ops_1000.png figures/fig5.png
}

run_phold() {
  echo "Running PHOLD experiments..."
  cd PARSIR
  ./phold.sh
  ./figures.sh phold
  cd ..
  mkdir -p figures
  mv PARSIR/plots/phold/fig6.png figures/fig6.png
}

run_pcs() {
  echo "Running PCS experiments..."
  cd PARSIR
  ./pcs.sh
  ./figures.sh pcs
  cd ..
  mkdir -p figures
  mv PARSIR/plots/pcs/fig7.png figures/fig7.png
}

# --- Figures ---

run_figures() {
  mkdir -p figures
  cd Checkpoint
  ./figures.sh
  cd ..
  cp Checkpoint/plots/ckpt_comparison_size_1MB_grid_32_chunk_32_ops_1000.png figures/fig4.png
  cp Checkpoint/plots/ckpt_comparison_size_4MB_grid_256_chunk_256_ops_1000.png figures/fig5.png
  cd PARSIR
  ./figures.sh
  cd ..
  mv PARSIR/plots/phold/fig6.png figures/fig6.png
  mv PARSIR/plots/pcs/fig7.png figures/fig7.png
}

# --- Remove Artifacts ---

run_clean() {
  echo "Removing all plots and figures produced..."
  rm -rf ./figures
  cd Checkpoint
  rm -rf ./plots
  cd MVM_CHUNK
  #rm -f ./chunk_repeat_test_results.csv ./chunk_test_results.csv
  make clean
  cd ..
  cd MVM_GRID_CKPT
  #rm -f ./ckpt_repeat_test_results.csv ./ckpt_test_results.csv
  make clean
  cd ../..
  cd ./PARSIR
  rm -rf ./plots
  #rm -f ./phold.csv ./pcs.csv
  cd build
  make clean
}

# --- Main ---

if [ $# -eq 0 ]; then
  echo "No argument provided. Running ALL tests..."
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
      figures)
        run_figures
        ;;
      clean)
        run_clean
        ;;
      *)
        echo "Unknown test: $arg"
        echo "Valid options: kick, instr_cost, phold, pcs, figures, clean"
        exit 1
        ;;
    esac
  done
fi