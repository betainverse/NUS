#!/bin/csh -f

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
| nmrPipe  -fn REV -sw \
| nmrPipe  -fn TP \
| nmrPipe  -fn ZTP \
> rec/data.pipe
pipe2xyz -in rec/data.pipe -out rec/test%03d.ft3 -x
pipe2ucsf rec/data.pipe CBCAcoNH.ucsf
proj3D.tcl -in rec/test%03d.ft3
