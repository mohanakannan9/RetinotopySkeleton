#!/bin/sh

MCR_CACHE_ROOT=/tmp
export MCR_CACHE_ROOT

echo Now issuing MATLAB command.
~/mcc/$MYSCRIPT /export/matlab/R2012b/MCR $MYARG1 $MYARG2 $PBS_ARRAYID
