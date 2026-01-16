#!/bin/bash

set -euo pipefail

# This script is meant to be called by a SLURM wrapper script
# Do NOT submit with sbatch


###### manage YEAR AND OPADIR input from command line
while getopts y:i:o: flag; do
    case "${flag}" in
        y) YEAR=${OPTARG};;
        i) INPUTDIR=${OPTARG};;
        o) OUTDIR=${OPTARG};;
        *) echo "Usage: $0 -y YEAR -i INPUTDIR -o OUTDIR"; exit 1;;
    esac
done


if [ -z "$YEAR" ] || [ -z "$INPUTDIR" ] || [ -z "$OUTDIR" ]; then
    echo "Error: both -y YEAR and -i INPUTDIR and -o OUTDIR are required"
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


##################### ARCHIVE: AVE_FREQ_3 #####################
echo "Start copying AVE_FREQ_3 at $(date) for year $YEAR"
mkdir -p "$OUTDIR"

# Copy .tar files directly in INPUTDIR
find "$INPUTDIR" -maxdepth 1 -type f -name '*.tar' | \
  xargs -I{} -P 16 bash -c '
    src="{}"
    dest="'$OUTDIR'/$(basename "{}")"
    rsync -av "$src" "$dest"
  '

# Copy .tar files in parallel from bottom if exists
if [ -d "$INPUTDIR/bottom" ]; then
  export BINDIR="$INPUTDIR/bottom"
  export BOUTDIR="$OUTDIR/bottom"
  mkdir -p "$BOUTDIR"

  find "$BINDIR" -type f -name '*.tar' | \
    sed "s|^$BINDIR||" | \
    xargs -I{} -P 16 bash -c '
      src="$BINDIR/{}"
      dest="$BOUTDIR/{}"
      mkdir -p "$(dirname "$dest")"
      rsync -av "$src" "$dest"
  '
fi

# Copy .tar files in parallel from surf if exists
if [ -d "$INPUTDIR/surf" ]; then
  export SINDIR="$INPUTDIR/surf"
  export SOUTDIR="$OUTDIR/surf"
  mkdir -p "$SOUTDIR"

  find "$SINDIR" -type f -name '*.tar' | \
    sed "s|^$SINDIR||" | \
    xargs -I{} -P 16 bash -c '
      src="$SINDIR/{}"
      dest="$SOUTDIR/{}"
      mkdir -p "$(dirname "$dest")"
      rsync -av "$src" "$dest"
  '
fi

echo "Finished copying year $YEAR at $(date)"

[ -d "$INPUTDIR/bottom" ] && compare_and_remove "$INPUTDIR/bottom" "$OUTDIR/bottom"
[ -d "$INPUTDIR/surf" ] && compare_and_remove "$INPUTDIR/surf" "$OUTDIR/surf"
compare_and_remove "$INPUTDIR" "$OUTDIR"


