#!/bin/sh

MCR_CACHE_ROOT=/tmp/MCC_CACHE_${USER}
export MCR_CACHE_ROOT

echo Now issuing MATLAB command.
$HCPRETINODIR/mcc/$MYSCRIPT /export/matlab/R2012b/MCR $MYARG1 $MYARG2 $PBS_ARRAYID
