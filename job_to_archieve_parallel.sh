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

YEAR=2024
INPUTDIR=/g100_scratch/userexternal/camadio0/V12C/TRANSITION/wrkdir/MODEL/
OUTDIR=/g100_work/OGS_test2528/V12C/EIS/TRANSITION/wrkdir/archive/
DIRS=("AVE_FREQ_1_tar" "AVE_FREQ_2_tar" "AVE_FREQ_3_tar" "RESTARTS_tar")

for AVEDIR in "${DIRS[@]}"; do
    echo "Start safe move of $AVEDIR for year $YEAR at $(date)"

    mkdir -p "$OUTDIR/$AVEDIR/$YEAR/"

    rsync -a --info=progress2 --delete-after "$INPUTDIR/$AVEDIR/$YEAR/" "$OUTDIR/$AVEDIR/$YEAR/"
    RC=$?

    # 2) if  rsync ok delete files in inputdir 
    if [ $RC -eq 0 ]; then
        echo "rsync ok: removing originals from $INPUTDIR/$AVEDIR/$YEAR/"
        find "$INPUTDIR/$AVEDIR/$YEAR/" -type f -delete
    else
        echo "ERROR: rsync failed for $AVEDIR year $YEAR. Originals NOT removed."
        exit 1
    fi

    echo "Finished safe move of $AVEDIR for year $YEAR at $(date)"
done

echo "=========================================="
echo " Job ARCH completed "
echo " End time: $(date)"
echo "=========================================="



