import argparse

def argument():
    parser = argparse.ArgumentParser(
        description='Script to process variable by name.',
        formatter_class=argparse.RawTextHelpFormatter
    )

    parser.add_argument('--varname', '-v',
                        type=str,
                        required=True,
                        help='Name of the variable to process (e.g., ALK, etc.)')

    parser.add_argument('--diffpath', '-d',
                        type=str,
                        help='Path to diff.nc')

    parser.add_argument('--freq', '-f',
                        type=str,
                        help='AVE_FREQ_1, 2,3 '
                        )

    return parser.parse_args()

args = argument()

from netCDF4 import Dataset
import numpy as np
import sys
import os

if not os.path.exists(args.diffpath):
    print(f"KO File {args.diffpath} not found!")
    sys.exit(1)

nc = Dataset(args.diffpath)
modelvarname = args.varname
data = nc.variables[modelvarname][:]

min_val = data.min()
max_val = data.max()

if args.freq=="AVE_FREQ_3":
   if abs(min_val) <= 10e-6 and abs(max_val) <= 10e-6:
       print("ok, Files are numerically identical (min and max are 0).")
   else:
       print("KO Difference found (min and/or max != 0).")
       sys.exit(1)
else:       

   if min_val == 0 and max_val == 0:
       print("ok Files are numerically identical (min and max are 0).")
       print(args.diffpath)
   else:
       print("KO Difference found (min and/or max != 0).")
       sys.exit(1)




