#!/bin/csh

## Adjust the name of your schedule at the top
## Adjust sweep widths, carrier frequencies, and spectrometer frequencies
## In the var2pipe section.
## -zN must be the length of your schedule
## -yN must be 4
## -yMODE and -zMODE must BOTH be Real
## If you need Rance-Kay for the Nitrogen dimension, use the ranceZ macro
## at the bottom of the section.
## After running this script once and adjusting your phase correction,
## enter that phase correction in the bottom section.

set samplingschedule = ./gcbca_co_nh_S.hdr_3

if( -e $samplingschedule ) then 
    #awk '{print $2,$1}' $samplingschedule > ist.sched
    cp $samplingschedule ist.sched
    echo 
    echo length of sampling schedule:
    wc ist.sched
    echo 
else
    echo 
    echo sampling schedule $samplingschedule not found
    exit
endif 

var2pipe -in ./fid \
 -noaswap  \
  -xN              2048  -yN                 4  -zN              1000  \
  -xT              1024  -yT                 4  -zT              1000  \
  -xMODE        Complex  -yMODE           Real  -zMODE           Real  \
  -xSW        11261.261  -ySW        14480.140  -zSW         2755.200  \
  -xOBS    799.7142019    -yOBS    201.0954752    -zOBS     81.0436026    \
  -xCAR      4.7593479    -yCAR     43.1258533    -zCAR    119.1295533    \
  -xLAB              HN  -yLAB             C13  -zLAB             N15  \
  -ndim               3  -aq2D          States                         \
#| nmrPipe -fn MAC -macro $NMRTXT/ranceY.M -noRd -noWr   \
| nmrPipe -fn MAC -macro /software/istHMS/ranceZphf.M -noRd -noWr   \
| pipe2xyz -x  -out ./data/test%03d.fid -verb -ov  

rm -rf xyz

xyz2pipe -in data/test%03d.fid -x \
| nmrPipe -fn SOL \
| nmrPipe  -fn SP -off 0.5 -end 0.98 -pow 1 -c 1.0 \
| nmrPipe  -fn ZF -auto                          \
| nmrPipe  -fn FT -verb                             \
| nmrPipe  -fn PS -p0 115.0  -p1 0.0 -di              \
| nmrPipe  -fn EXT -left -sw           \
#| nmrPipe  -fn EXT -x1 6.4ppm -xn 10.2ppm -sw           \
| pipe2xyz -ov -out xyz/test%03d.nus -x

echo
echo Press enter/return to continue to check phasing with nmrDraw.
echo If you change the phase, rerun NUSproc1.com to check again.
echo Otherwise, proceed to NUSproc2.com.
setenv Anykey "$<" 

nmrDraw xyz/test001.nus

