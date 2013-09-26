#!/bin/csh -f

## Enter your phase correction in the top xyz2pipe section. 
## Adjust the name of your output at the bottom. 
## You may need to make another copy of the bottom section in order
## To make adjustments to the final processing step without repeating
## the reconstruction.

rm -rf yzx # clean up
rm -rf yzx_ist # clean up
mkdir yzx
mkdir yzx_ist

xyz2pipe -in data/test%03d.fid -x \
| nmrPipe -fn SOL \
| nmrPipe  -fn SP -off 0.5 -end 0.98 -pow 1 -c 1 -size 350 \
| nmrPipe  -fn ZF -auto                          \
| nmrPipe  -fn FT -verb                             \
| nmrPipe  -fn PS -p0 -58.0 -p1 0.0 -di              \
| nmrPipe  -fn EXT -x1 6.0ppm -xn 10.5ppm -sw           \
| nmrPipe  -fn POLY -auto -ord 1 \
| pipe2xyz -ov -out yzx/test%03d.nus -z

parallel -j 100% './ist.csh {} > /dev/null; echo {}' ::: yzx/test*.nus

xyz2pipe -in yzx_ist/test%03d.phf | ~/bin/IST/phf2pipe_20130530_64b -user 1 -xproj xz.ft1 -yproj yz.ft1 | pipe2xyz -out rec/test%03d.ft1

xyz2pipe -in rec/test%03d.ft1 -x \
| nmrPipe  -fn SP -off 0.5 -end 0.98 -pow 1 -c 0.5 \
| nmrPipe  -fn ZF -auto                       \
| nmrPipe  -fn FT -verb                           \
| nmrPipe  -fn PS -p0 0 -p1 0.0 -di              \
| nmrPipe  -fn POLY -auto -ord 1 \
| nmrPipe  -fn CS -ls 3ppm -sw \
| nmrPipe  -fn TP \
| nmrPipe  -fn SP -off 0.5 -end 0.98 -pow 1 -c 0.5 \
| nmrPipe  -fn ZF -auto  \
| nmrPipe  -fn FT -verb                       \
| nmrPipe  -fn PS -p0 0.0 -p1 0.0 -di              \
| nmrPipe  -fn POLY -auto -ord 1 \
#| nmrPipe  -fn REV -sw \
| nmrPipe  -fn TP \
| nmrPipe  -fn ZTP \
> rec/data.pipe
pipe2xyz -in rec/data.pipe -out rec/test%03d.ft3 -x
pipe2ucsf rec/data.pipe CBCACONH.ucsf
proj3D.tcl -in rec/test%03d.ft3
