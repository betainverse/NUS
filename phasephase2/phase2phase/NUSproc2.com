#!/bin/csh -f

## Enter your phase correction in the top xyz2pipe section. 
## Adjust the name of your output at the bottom. 
## Make sure the EXT line is appropriate for your protein. 
## You may need to make another copy of the bottom section in order
## To make adjustments to the final processing step without repeating
## the reconstruction.

rm -rf yzx # clean up
rm -rf yzx_ist # clean up
mkdir yzx
mkdir yzx_ist

xyz2pipe -in data/test%03d.fid -x \
| nmrPipe -fn SOL \
| nmrPipe  -fn SP -off 0.5 -end 0.98 -pow 1 -c 1 \
| nmrPipe  -fn ZF -auto                          \
| nmrPipe  -fn FT -verb                             \
| nmrPipe  -fn PS -p0 115.0 -p1 0.0 -di              \
| nmrPipe  -fn EXT -x1 5.7ppm -xn 10.4ppm -sw           \
| nmrPipe  -fn POLY -auto -ord 1 \
| pipe2xyz -ov -out yzx/test%03d.nus -z

parallel -j 100% './ist.com {} > /dev/null; echo {}' ::: yzx/test*.nus

xyz2pipe -in yzx_ist/test%03d.phf | phf2pipe_20130530_64b -user 1 -xproj xz.ft1 -yproj yz.ft1 | pipe2xyz -out rec/test%03d.ft1

# C then N
xyz2pipe -in rec/test%03d.ft1 -x \
| nmrPipe  -fn SP -off 0.5 -end 0.98 -pow 1 -c 0.5 \
| nmrPipe  -fn ZF -auto                       \
| nmrPipe  -fn FT -verb                           \
| nmrPipe  -fn PS -p0 0.0 -p1 0.0 -di              \
| nmrPipe  -fn POLY -auto -ord 1 \
| nmrPipe  -fn REV -sw \
#| nmrPipe  -fn CS -ls 3ppm -sw \
| nmrPipe  -fn TP \
| nmrPipe  -fn SP -off 0.5 -end 0.98 -pow 1 -c 0.5 \
| nmrPipe  -fn ZF -auto  \
| nmrPipe  -fn FT -verb                       \
| nmrPipe  -fn PS -p0 -90.0 -p1 0.0 -di              \
| nmrPipe  -fn POLY -auto -ord 1 \
| nmrPipe  -fn TP \
| nmrPipe  -fn ZTP \
> rec/data.pipe
pipe2xyz -in rec/data.pipe -out rec/test%03d.ft3 -x
#pipe2xyz -in rec/data.pipe -out CBCAcoNH.nv -nv -x
pipe2ucsf rec/data.pipe CBCAcoNHauto.ucsf
proj3D.tcl -in rec/test%03d.ft3
