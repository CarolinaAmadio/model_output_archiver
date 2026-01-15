#!/bin/bash

#SBATCH --job-name=ARCH10
#SBATCH -N2
#SBATCH --ntasks-per-node=16
#SBATCH --time=0:30:00
#SBATCH --mem=300gb
#SBATCH --account=OGS_test2528
#SBATCH --partition=g100_meteo_prod
#SBATCH --qos=qos_meteo


#module load parallel


#OPA_HOME=QUID_neccton_hind_run2/
#YEAR=2022

compare_and_remove() {
    local input_dir=$1
    local output_dir=$2
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
                rm "$input_file"
            else
                echo "$basename is different: not removed"
            fi
        else
            echo "$basename not found in $output_dir"
        fi
    '
}


###### manage YEAR AND OPADIR input from command line
while getopts y:i: flag; do
    case "${flag}" in
        y) YEAR=${OPTARG};;
        i) OPA_HOME=${OPTARG};;
        *) echo "Usage: $0 -y YEAR -i OPA_HOME"; exit 1;;
    esac
done

if [ -z "$YEAR" ] || [ -z "$OPA_HOME" ]; then
    echo "Error: both -y YEAR and -i OPA_HOME are required"
    exit 1
fi
###### END manage YEAR AND OPADIR input from command line


##################### ARCHIVE: AVE_FREQ_1 #####################

INPUTDIR="/g100_scratch/userexternal/camadio0/$OPA_HOME/wrkdir/MODEL/AVE_FREQ_1_tar/$YEAR/"
OUTDIR="/g100_work/OGS_test2528/camadio/Neccton_hindcast_ALL_SIMULATIONS_archieve/$OPA_HOME/AVE_FREQ_1_tar/$YEAR/"

export INPUTDIR OUTDIR

echo "Start copying AVE_FREQ_1 at $(date) for year $YEAR"
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


##################### ARCHIVE: AVE_FREQ_2 #####################

INPUTDIR="/g100_scratch/userexternal/camadio0/$OPA_HOME/wrkdir/MODEL/AVE_FREQ_2_tar/$YEAR/"
OUTDIR="/g100_work/OGS_test2528/camadio/Neccton_hindcast_ALL_SIMULATIONS_archieve/$OPA_HOME/AVE_FREQ_2_tar/$YEAR/"

export INPUTDIR OUTDIR

echo "Start copying AVE_FREQ_2 at $(date) for year $YEAR"
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


##################### ARCHIVE: AVE_FREQ_4 #####################

INPUTDIR="/g100_scratch/userexternal/camadio0/$OPA_HOME/wrkdir/MODEL/AVE_FREQ_4_tar/$YEAR/"
OUTDIR="/g100_work/OGS_test2528/camadio/Neccton_hindcast_ALL_SIMULATIONS_archieve/$OPA_HOME/AVE_FREQ_4_tar/$YEAR/"

export INPUTDIR OUTDIR

echo "Start copying AVE_FREQ_4 at $(date) for year $YEAR"
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

##################### ARCHIVE: AVE_FREQ_3 #####################

INPUTDIR="/g100_scratch/userexternal/camadio0/$OPA_HOME/wrkdir/MODEL/AVE_FREQ_3_tar/$YEAR/"
OUTDIR="/g100_work/OGS_test2528/camadio/Neccton_hindcast_ALL_SIMULATIONS_archieve/$OPA_HOME/AVE_FREQ_3_tar/$YEAR/"

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


