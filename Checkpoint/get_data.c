#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define MAX_LINE_LENGTH 1024

typedef struct {
    char size[32];
    char cache_flush[32];
    char mod[32];
    char ops[32];
    char writes[32];
    char reads[32];
    char ckpt_mean[32];
    char ckpt_ci[32];
    char restore_mean[32];
    char restore_ci[32];
} GridCkptRow;

typedef struct {
    char size[32];
    char cache_flush[32];
    char chunk_size[32];
    char ops[32];
    char writes[32];
    char reads[32];
    char ckpt_mean[32];
    char ckpt_ci[32];
    char restore_mean[32];
    char restore_ci[32];
} ChunkCkptRow;

typedef struct {
    char size[32];
    char cache_flush[32];
    char mod[32];
    char ops[32];
    char writes[32];
    char reads[32];
    char reps[32];
    char ckpt_mean[32];
    char ckpt_ci[32];
    char restore_mean[32];
    char restore_ci[32];
} GridCkptRepRow;

typedef struct {
    char size[32];
    char cache_flush[32];
    char chunk_size[32];
    char ops[32];
    char writes[32];
    char reads[32];
    char reps[32];
    char ckpt_mean[32];
    char ckpt_ci[32];
    char restore_mean[32];
    char restore_ci[32];
} ChunkCkptRepRow;

int main(int argc, char *argv[]) {
    FILE *mvm_file, *chunk_ckpt_file, *chunk_ckpt_rep_file, *grid_ckpt_rep_file,
        *grid_ckpt_file, *output_file;
    char line[MAX_LINE_LENGTH];
    char *endptr;
    int size, cache_flush, mod, ops, chunk_size;

    if (argc < 6) {
        fprintf(stderr,
                "Usage: %s <size> <cache_flush> <mod> <chunk_size> <ops>\n",
                argv[0]);
        return EXIT_FAILURE;
    }

    size = strtol(argv[1], &endptr, 16);
    if (*endptr != '\0' || size <= 0) {
        fprintf(stderr, "Size must be in hex\n");
        return EXIT_FAILURE;
    }

    cache_flush = strtol(argv[2], &endptr, 10);
    if (*endptr != '\0' || cache_flush < 0 || cache_flush > 1) {
        fprintf(stderr, "cache_flush must be 0 or 1\n");
        return EXIT_FAILURE;
    }

    mod = strtol(argv[3], &endptr, 10);
    if (*endptr != '\0' || (mod != 8 && mod != 16 && mod != 32 && mod != 64 &&
                            mod != 128 && mod != 256)) {
        fprintf(stderr, "mod must be 8, 16, 32, 64, 128, 256 instead of %d\n",
                mod);
        return EXIT_FAILURE;
    }

    chunk_size = strtol(argv[4], &endptr, 10);
    if (*endptr != '\0' || chunk_size < 32) {
        fprintf(stderr,
                "chunk_size must be an integer greater or equal to 32.\n");
        return EXIT_FAILURE;
    }

    ops = strtol(argv[5], &endptr, 10);
    if (*endptr != '\0' || ops <= 0) {
        fprintf(stderr, "Ops must be an integer greater or equal to 1.\n");
        return EXIT_FAILURE;
    }

    grid_ckpt_file = fopen("MVM_GRID_CKPT/ckpt_test_results.csv", "r");
    chunk_ckpt_file = fopen("MVM_CHUNK/chunk_test_results.csv", "r");
    grid_ckpt_rep_file =
        fopen("MVM_GRID_CKPT/ckpt_repeat_test_results.csv", "r");
    chunk_ckpt_rep_file =
        fopen("MVM_CHUNK/chunk_repeat_test_results.csv", "r");
    output_file = fopen("plot_data.csv", "w");

    if (!chunk_ckpt_file || !grid_ckpt_file || !output_file) {
        perror("Error opening files!");
        return EXIT_FAILURE;
    }

    fprintf(output_file,
            "size,cache_flush,mod,chunk,ops,writes,reads,"
            "grid_ckpt_mean,grid_ckpt_ci,grid_ckpt_10_reps_mean,"
            "grid_ckpt_10_reps_ci,"
            "chunk_ckpt_mean,chunk_ckpt_ci,chunk_ckpt_10_reps_mean,"
            "chunk_ckpt_10_reps_ci\n");

    GridCkptRow grid_row;
    ChunkCkptRow chunk_row;
    GridCkptRepRow grid_rep_row;
    ChunkCkptRepRow chunk_rep_row;

    fgets(line, sizeof(line), grid_ckpt_file);
    while (fgets(line, sizeof(line), grid_ckpt_file)) {
        sscanf(line, "%[^,],%[^,],%[^,],%[^,],%[^,],%[^,],%[^,],%[^,],%[^,],%s",
               grid_row.size, grid_row.cache_flush, grid_row.mod, grid_row.ops,
               grid_row.writes, grid_row.reads, grid_row.ckpt_mean,
               grid_row.ckpt_ci, grid_row.restore_mean, grid_row.restore_ci);
        if (strtol(grid_row.size, &endptr, 16) != size ||
            strtol(grid_row.cache_flush, &endptr, 10) != cache_flush ||
            strtol(grid_row.mod, &endptr, 10) != mod ||
            strtol(grid_row.ops, &endptr, 10) != ops) {
            continue;
        }
        fprintf(output_file, "%s,%d,%d,%d,%d,%s,%s,%s,%s", grid_row.size,
                cache_flush, mod, chunk_size, ops, grid_row.writes,
                grid_row.reads, grid_row.ckpt_mean, grid_row.ckpt_ci);

        fseek(grid_ckpt_rep_file, 0, SEEK_SET);
        fgets(line, sizeof(line), grid_ckpt_rep_file);
        while (fgets(line, sizeof(line), grid_ckpt_rep_file)) {
            sscanf(line, "%[^,],%[^,],%[^,],%[^,],%[^,],%[^,],%[^,],%[^,],%[^,],%[^,],%s",
                   grid_rep_row.size, grid_rep_row.cache_flush,
                   grid_rep_row.mod, grid_rep_row.ops, grid_rep_row.writes,
                   grid_rep_row.reads, grid_rep_row.reps,
                   grid_rep_row.ckpt_mean, grid_rep_row.ckpt_ci, grid_rep_row.restore_mean, grid_rep_row.restore_ci);
            if (strtol(grid_rep_row.mod, &endptr, 10) == mod &&
                !strcmp(grid_rep_row.size, grid_row.size) &&
                !strcmp(grid_rep_row.cache_flush, grid_row.cache_flush) &&
                !strcmp(grid_rep_row.ops, grid_row.ops) &&
                !strcmp(grid_rep_row.writes, grid_row.writes) &&
                !strcmp(grid_rep_row.reads, grid_row.reads) &&
                !strcmp(grid_rep_row.reps, "10")) {
                fprintf(output_file, ",%s,%s", grid_rep_row.ckpt_mean,
                        grid_rep_row.ckpt_ci);
                break;
            }
        }

        fseek(chunk_ckpt_file, 0, SEEK_SET);
        fgets(line, sizeof(line), chunk_ckpt_file);
        while (fgets(line, sizeof(line), chunk_ckpt_file)) {
            sscanf(line, "%[^,],%[^,],%[^,],%[^,],%[^,],%[^,],%[^,],%[^,],%[^,],%s",
                   chunk_row.size, chunk_row.cache_flush, chunk_row.chunk_size,
                   chunk_row.ops, chunk_row.writes, chunk_row.reads,
                   chunk_row.ckpt_mean, chunk_row.ckpt_ci, chunk_row.restore_mean, chunk_row.restore_ci);
            if (strtol(chunk_row.chunk_size, &endptr, 10) == chunk_size &&
                !strcmp(grid_row.size, chunk_row.size) &&
                !strcmp(grid_row.cache_flush, chunk_row.cache_flush) &&
                !strcmp(grid_row.ops, chunk_row.ops) &&
                !strcmp(grid_row.writes, chunk_row.writes) &&
                !strcmp(grid_row.reads, chunk_row.reads)) {
                fprintf(output_file, ",%s,%s", chunk_row.ckpt_mean,
                        chunk_row.ckpt_ci);
                break;
            }
        }

        fseek(chunk_ckpt_rep_file, 0, SEEK_SET);
        fgets(line, sizeof(line), chunk_ckpt_rep_file);
        while (fgets(line, sizeof(line), chunk_ckpt_rep_file)) {
            sscanf(line, "%[^,],%[^,],%[^,],%[^,],%[^,],%[^,],%[^,],%[^,],%[^,],%[^,],%s",
                   chunk_rep_row.size, chunk_rep_row.cache_flush,
                   chunk_rep_row.chunk_size, chunk_rep_row.ops,
                   chunk_rep_row.writes, chunk_rep_row.reads,
                   chunk_rep_row.reps, chunk_rep_row.ckpt_mean,
                   chunk_rep_row.ckpt_ci, chunk_rep_row.restore_mean, chunk_rep_row.restore_ci);
            if (strtol(chunk_rep_row.chunk_size, &endptr, 10) == chunk_size &&
                !strcmp(grid_row.size, chunk_rep_row.size) &&
                !strcmp(grid_row.cache_flush, chunk_rep_row.cache_flush) &&
                !strcmp(grid_row.ops, chunk_rep_row.ops) &&
                !strcmp(grid_row.writes, chunk_rep_row.writes) &&
                !strcmp(grid_row.reads, chunk_rep_row.reads) &&
                !strcmp("10", chunk_rep_row.reps)) {
                fprintf(output_file, ",%s,%s\n", chunk_rep_row.ckpt_mean,
                        chunk_rep_row.ckpt_ci);
                break;
            }
        }
    }

    fclose(chunk_ckpt_file);
    fclose(grid_ckpt_file);
    fclose(output_file);

    return EXIT_SUCCESS;
}
