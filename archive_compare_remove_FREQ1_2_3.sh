#!/bin/bash

set -euo pipefail

# This script is meant to be called by a SLURM wrapper script
# Do NOT submit with sbatch


###### manage YEAR, OPADIR, and FREQ input from command line
while getopts y:i:f:o: flag; do
    case "${flag}" in
        y) YEAR=${OPTARG};;
        i) INPUTDIR=${OPTARG};;
        f) FREQ=${OPTARG};;
	o) OUTDIR=${OPTARG};;
        *) echo "Usage: $0 -y YEAR -i INPUTDIR -f FREQ(1|2|4 ) -o OUTDIR"; exit 1;;
    esac
done

if [ -z "$YEAR" ] || [ -z "$INPUTDIR" ] || [ -z "$FREQ" ] || [ -z "$OUTDIR" ]; then
    echo "Error: -y YEAR, -i INPUTDIR, -f FREQ, and -o OUTDIR are required"
    exit 1
fi

# check if FREQ is valid
if [[ "$FREQ" != "1" && "$FREQ" != "2" && "$FREQ" != "3" ]]; then
    echo "Error: FREQ must be 1, 2, or 4"
    exit 1
fi

###### END manage YEAR AND OPADIR input from command line


compare_and_remove() {
    local input_dir="$1"
    local output_dir="$2"
    local log_file="removed_files_${YEAR}.log"

    export YEAR input_dir output_dir log_file
    find "$input_dir" -maxdepth 1 -type f -iname "*.tar" | parallel --no-notice -j 16 '
        input_file={}
        basename=$(basename "$input_file")
        output_file="$output_dir/$basename"

        if [ -f "$output_file" ]; then
            md5_input=$(md5sum "$input_file" | awk "{print \$1}")
            md5_output=$(md5sum "$output_file" | awk "{print \$1}")

            echo "Comparing $basename"
            echo "MD5 input : $md5_input"
            echo "MD5 output: $md5_output"

            if [ "$md5_input" = "$md5_output" ]; then
                echo "$basename is identical: removing from $input_dir"
                echo "$input_file" >> "$log_file"
                echo "rm $input_file"
            else
                echo "$basename is different: not removed"
            fi
        else
            echo "$basename not found in $output_dir"
        fi
    '
}

##################### ARCHIVE: AVE_FREQ_${FREQ} #####################
export INPUTDIR OUTDIR

echo "Start copying AVE_FREQ_${FREQ} at $(date) for year $YEAR"
mkdir -p "$OUTDIR"

# Parallel copy
find "$INPUTDIR" -type f -name '*.tar' | \
  sed "s|^$INPUTDIR||" | \
  xargs -I{} -P 16 bash -c '
    src="$INPUTDIR/{}"
    dest="$OUTDIR/{}"
    mkdir -p "$(dirname "$dest")"
    rsync -av "$src" "$dest"
'

# Wait not necessary here because xargs completes before proceeding
compare_and_remove "$INPUTDIR" "$OUTDIR"
