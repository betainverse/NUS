#!/bin/csh

## Adjust the name of your schedule at the top
## Adjust sweep widths, carrier frequencies, and spectrometer frequencies
## In the var2pipe section.
## -yMODE and -zMODE must BOTH be Real
## -yN must be 4
## -zN must be the length of your schedule
## If you need Rance-Kay for the Nitrogen dimension, use the ranceY macro
## at the bottom of the section.
## After running this script once and adjusting your phase correction,
## enter that phase correction in the bottom section.

set samplingschedule = ../gcbca_co_nh_S.hdr_3

if( -e $samplingschedule ) then 
    if( ! -e ./reversed.sched ) then 
	awk '{print $2,$1}' $samplingschedule > ./reversed.sched
    endif
    echo 
    echo length of sampling schedule:
    wc ./reversed.sched
    echo 
else
    echo 
    echo sampling schedule $samplingschedule not found
    exit
endif 


var2pipe -in ./fid \
 -noaswap -aqORD 1 \
  -xN              2048  -yN                 4  -zN               320  \
  -xT              1024  -yT                 4  -zT               320  \
  -xMODE        Complex  -yMODE           Real  -zMODE           Real  \
  -xSW        11261.261  -ySW         2836.276  -zSW        16089.230  \
  -xOBS         799.714  -yOBS          81.044  -zOBS         201.097  \
  -xCAR           4.773  -yCAR         120.141  -zCAR          48.548  \
  -xLAB              HN  -yLAB             N15  -zLAB             C13  \
  -ndim               3  -aq2D          States                         \
| nmrPipe -fn MAC -macro $NMRTXT/ranceY.M -noRd -noWr   \
#| nmrPipe -fn MAC -macro ~/bin/IST/ranceZphf.M -noRd -noWr   \
| pipe2xyz -x  -out ./data/test%03d.fid -verb -ov  

rm -rf xyz

xyz2pipe -in data/test%03d.fid -x \
| nmrPipe -fn SOL \
| nmrPipe  -fn SP -off 0.5 -end 0.98 -pow 1 -c 1.0 \
| nmrPipe  -fn ZF -auto                          \
| nmrPipe  -fn FT -verb                             \
| nmrPipe  -fn PS -p0 0.0  -p1 0.0 -di              \
| nmrPipe  -fn EXT -left -sw           \
#| nmrPipe  -fn EXT -x1 6.4ppm -xn 10.2ppm -sw           \
| pipe2xyz -ov -out xyz/test%03d.nus -x

echo
echo Press any key to continue to check phasing with nmrDraw.
echo If you change the phase, rerun NUSproc1.com to check again.
echo Otherwise, proceed to NUSproc2.com.
setenv Anykey "$<" 

nmrDraw xyz/test001.nus

