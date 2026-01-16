#!/bin/bash

##set -euo pipefail
module load nco
module load ncview
source /g100_work/OGS23_PRACE_IT/COPERNICUS/py_env_3.9.18_new/bin/activate

###### manage YEAR, OPADIR, and FREQ input from command line
while getopts y:i:f:t: flag; do
    case "${flag}" in
        y) YEAR=${OPTARG};;
        i) INPUTDIR=${OPTARG};;
	f) FREQ=${OPTARG};;
	t) TARDIR=${OPTARG};;
        *) echo "Usage: $0 -y YEAR -i INPUTDIR -f FREQ(1|2|3) -t TARDIR"; exit 1;;
    esac
done

# check mandatory arguments
if [ -z "$YEAR" ] || [ -z "$INPUTDIR" ] || [ -z "$FREQ" ] || [ -z "$TARDIR" ]; then
    echo "Error: -y YEAR, -i INPUTDIR, -f FREQ, and -t TARDIR are required"
    exit 1
fi

# check if FREQ is valid
if [[ "$FREQ" != "1" && "$FREQ" != "2" && "$FREQ" != "3" ]]; then
    echo "Error: FREQ must be 1, 2, or 3"
    exit 1
fi

###### END manage YEAR AND OPADIR input from command line

MAX_JOBS=16
SAMPLE_SIZE=5

mkdir -p TMPS/

echo "Processing AVE_FREQ_$FREQ..."

if [[ "$FREQ" == "AVE_FREQ_3" ]]; then
       INPUTDIR="$INPUTDIR/tosave/"
fi

# if files exist
if ! compgen -G "$INPUTDIR/ave.*.nc" > /dev/null; then
  echo "KO No files in $INPUTDIR"
  exit 0
fi

# data extraction
ALL_DATES=$(ls "$INPUTDIR"/ave.*.nc | sed -n 's|.*ave.\([0-9]\{8\}-[0-9:]\{8\}\).*|\1|p' | sort -u)

# choosing randomly a set of dates
DATES=$(echo "$ALL_DATES" | shuf | head -n $SAMPLE_SIZE)

if [[ "$FREQ" == "AVE_FREQ_3" ]]; then
   VARLIST="Ed_0375 Ed_0400 Ed_0425 Ed_0475 Ed_0500 Es_0375 Es_0400 Es_0425 Es_0475 Es_0500 Eu_0375 Eu_0400 Eu_0425 Eu_0475 Eu_0500"
else
   VARLIST=$(ls "$TARDIR"/*.tar | xargs -n1 basename | sed 's/\.tar$//')
fi

job_count=0

for var in $VARLIST; do
  for date in $DATES; do
    (
      filename="ave.${date}.${var}.nc"

      tar -xf "$TARDIR/${var}.tar" "$filename" || {
        echo "KO Failed to extract $filename from $var.tar"
        exit 0
      }

      mv "$filename" TMPS/

      INPUTFILE="$INPUTDIR/$filename"
      TESTFILE="TMPS/$filename"

      DIFFOUT="TMPS/${var}_${date}.nc"

      if [[ ! -f "$INPUTFILE" ]]; then
        echo "KO Missing input file: $INPUTFILE"
        exit 0
      fi

      ncdiff "$TESTFILE" "$INPUTFILE" "$DIFFOUT"
      echo "checking $INPUTFILE"
      python check_max_min_val.py --varname $var --diffpath $DIFFOUT --freq $FREQ
    ) &

    ((job_count++))
    if (( job_count % MAX_JOBS == 0 )); then
      wait
    fi
  done
done

wait

rm -r TMPS/

