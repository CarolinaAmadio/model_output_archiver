#!/bin/bash

#SBATCH --job-name=ARCH
#SBATCH -N1
#SBATCH --ntasks-per-node=16
#SBATCH --time=03:30:00
#SBATCH --mem=300gb
#SBATCH --account=OGS_test2528
#SBATCH --partition=g100_meteo_prod
#SBATCH --qos=qos_meteo


echo "=========================================="
echo " Job ARCH started on $(hostname) "
echo " Start time: $(date)"
echo "=========================================="

# Può essere uno o più anni: es.
# YEAR="2022 2023 2024"
YEAR="2024"

INPUTDIR=/g100_scratch/userexternal/gbolzon0/Clean/TRANSITION/RESTARTS/
OUTDIR=/g100_work/OGS_test2528/V12C/EIS/TRANSITION/wrkdir/archive/RESTARTS_tar/


mkdir -p "$OUTDIR"

for Y in $YEAR; do

    echo "Coping files for YEAR = $Y"
    echo "Start at $(date)"

    # rsync con progress e preservazione permessi
    rsync -av --info=progress2 \
        "$INPUTDIR"/*"$Y"* \
        "$OUTDIR"/

    RC=$?

    if [ $RC -eq 0 ]; then
        echo "rsync OK for year $Y"
    else
        echo "ERROR: rsync FAILED for year $Y"
        exit 1
    fi

    echo "Finished YEAR = $Y at $(date)"
    echo "------------------------------------------"

done

echo "=========================================="
echo " Job ARCH completed "
echo " End time: $(date)"
echo "=========================================="

