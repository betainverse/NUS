#!/bin/csh 

set F = $1

set in = $F:t
set out = $F:t:r.phf


echo $in $out 

#istHMS_20130530_64b -dim 2 -incr 1 -xN 128 -yN 128 -user 1  \
istHMS_20130530_64b -dim 2 -incr 1 -autoN 1 -user 1  \
    -itr 400 -verb 0 -ref 0 -vlist ./ist.sched \
        < ./yzx/${in} >! ./yzx_ist/${out}
