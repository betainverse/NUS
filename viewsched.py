#!/usr/bin/env python
"""
Read in a nonuniform sampling schedule.
Output a graph depicting that schedule.
"""
import sys
import pylab
#from math import sqrt
import matplotlib.lines as mpllines
import matplotlib.ticker as mplticker

def main():
    if len(sys.argv) != 3:
        print "Usage:"
        print "sparkygraph.py schedule.hdr_3 chart.pdf"
        return

    infile = sys.argv[1]
    outfile = sys.argv[2]
    openfile = open(infile,'r')
    xcoords=[]
    ycoords=[]
    #heights = True
    for line in openfile.readlines():
        coords = line.split()
        if len(coords)==2:
            xcoords.append(int(coords[0]))
            ycoords.append(int(coords[1]))
    openfile.close()
    fig=pylab.figure()
    pylab.scatter(xcoords,ycoords,marker='o',s=8)
    pylab.xlabel("13C acquisition index")
    pylab.ylabel("15N acquisition index")
    axes = fig.gca()
    axes.set_aspect('equal')
    pylab.xlim(min(xcoords),max(xcoords))
    pylab.ylim(min(ycoords),max(ycoords))
    pylab.savefig(outfile)
    

main()
