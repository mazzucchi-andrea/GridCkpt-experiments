# SPDX-FileCopyrightText: 2026 Andrea Mazzucchi <andrea.mazzucchi@tutamail.com>
# SPDX-FileCopyrightText: 2026 Francesco Quaglia <francesco.quaglia@uniroma2.it>
#
# SPDX-License-Identifier: GPL-3.0-or-later

set datafile separator ","
# Extract values from the second line of the CSV (skipping the header)
_size = system("tail -n +2 plot_data.csv | head -n 1 | cut -d',' -f1")
# cache_flush = system("tail -n +2 plot_data.csv | head -n 1 | cut -d',' -f2")
grid = system("tail -n +2 plot_data.csv | head -n 1 | cut -d',' -f3")
chunk = system("tail -n +2 plot_data.csv | head -n 1 | cut -d',' -f4")
ops = system("tail -n +2 plot_data.csv | head -n 1 | cut -d',' -f5")

if (_size eq "0x100000") {
     size = "1MB"
}
if (_size eq "0x400000") {
     size = "4MB"
}

# Convert ops to a numeric value
ops_n = ops + 0

outfile = sprintf("plots/ckpt_comparison_size_%s_grid_%s_chunk_%s_ops_%s.png", size, grid, chunk, ops)
set terminal png size 900,600 font 'Arial,18'
set output outfile

# Set the title for the plot
set title sprintf("Memory Area Size: %s, Grid Elem Size: %s B, Chunk Size %s B", size, grid, chunk) font 'Arial,18'

set xlabel "Percentage of Writes (%)" font 'Arial,18'
set ylabel "Execution Time (seconds)" font 'Arial,18'
set xtics font ",18"
set ytics font ",18"
set yrange [0:*]

# Define colors
set linetype 1 lc rgb "#3594cc"  # grid_ckpt 1 rep
set linetype 2 lc rgb "#ea801c"  # chunk_ckpt 1 rep
set linetype 3 lc rgb "#8cc5e3" # grid_ckpt 10 reps
set linetype 4 lc rgb "#f0b077"  # chunk_ckpt 10 reps

set style fill solid border -1
set grid ytics linestyle 0 linecolor rgb "#E0E0E0"

# Get statistics from the writes column (column 6)
stats 'plot_data.csv' using 6 skip 1 nooutput
# Calculate step as the difference between max and min divided by (number of points - 1)
step = (STATS_max - STATS_min) / (STATS_records - 1)
# Convert to percentage
step_pct = (step / ops_n) * 100
min_pct = (STATS_min / ops_n) * 100
max_pct = (STATS_max / ops_n) * 100
set xrange [(min_pct - step_pct):(max_pct + step_pct)]
set xtics step_pct rotate by -45
set format x "%.0f%%"

set boxwidth step_pct/5
set key inside left top

# Create three groups of bars with proper stacking
plot 'plot_data.csv' using (($6/ops_n*100)-1.5*(step_pct/5)):8:9 skip 1 with boxerrorbars lt 1 title "grid ckpt 1000 ops", \
'' using (($6/ops_n*100)-0.5*(step_pct/5)):12:13 skip 1 with boxerrorbars lt 2 title "chunk ckpt 1000 ops", \
'' using (($6/ops_n*100)+0.5*(step_pct/5)):10:11 skip 1 with boxerrorbars lt 3 title "grid ckpt 10000 ops", \
'' using (($6/ops_n*100)+1.5*(step_pct/5)):14:15 skip 1 with boxerrorbars lt 4 title "chunk ckpt 10000 ops", \