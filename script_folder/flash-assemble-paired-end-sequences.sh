#!/bin/sh
flash2 -h
echo $ENV_FILE_TEST


###S
#run flash
#flash manual: http://ccb.jhu.edu/software/FLASH/MANUAL
echo "#Assembling sequneces with flash"
    #loop ->
    echo "#Assembling $R1 and $R2"
    flash $R1 $R2 -m $m -x $x -r $r -f $f > FLASH.log
    #compolsury options: -m, -x, -r, -f
    #optional: -p, -M, -o, -s

echo "done"
echo "Paired-end sequences assembled with flash"
###S