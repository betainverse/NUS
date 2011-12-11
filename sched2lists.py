#!/nmr/programs/python/bin/python2.7
"""
sched2lists.py reads a varian sampling schedule generated by the tool at
http://sbtools.uchc.edu/nmr/sample_scheduler and generates a corresponding
list of delays, as well as lists of delays for uniformly sampling 2D planes.

The default schedule name is varian_def.scd and it should begin with 0, not 1.

Use sched2lists.py -h or sched2lists.py --help to learn more about inputs.
"""
import argparse

def write_delays_and_phases(basename,pointlines,increments):
    delayfile = basename+ "_delays"
    phasefile = basename+"_phases"    
    opendelays = open(delayfile,'w')
    openphases = open(phasefile,'w')
    for line in pointlines:
        delays = map(lambda x,y: x*int(y), increments, line.split())
        phases = [1+(int(x)%2) for x in line.split()]
        for delay in delays:
            opendelays.write('%.8f\n'%delay)
        for phase in phases:
            openphases.write('%d\n'%phase)
    opendelays.close()
    openphases.close()

def main():
    # Parse inputs, complain about some problems.
    parser = argparse.ArgumentParser(
        description="Convert non-linear sampling schedule in the Varian format to VClists and VDlists of delays and phases for running on Bruker. First generate the schedule using the tool at  http://sbtools.uchc.edu/nmr/sample_scheduler. Delay and Phase lists for linearly sampling 2D planes are also generated.",
        epilog = "The default schedule name is varian_def.scd and it should begin with 0, not 1.")
    parser.add_argument("-s", "--sw", dest="sw", type=float, nargs='+',
                   help='Sweep widths (Hz) for each of the indirect dimensions, in the same order as the columns in the sampling schedule. Required.')
    parser.add_argument("-m", "--mi", metavar="MaxIncrement", dest="mi", type=int, nargs='+',
                        help='Max increment for each of the indirect dimensions, in the same order as the columns in the sampling schedule. Required.')
    parser.add_argument("-i", "--input", dest="infile",default='varian_def.scd',
                      help="Name of the generated schedule. Defaults to varian_def.scd", metavar="INFILE")
    parser.add_argument("-o", "--output", action="store",dest="outfile",default='nls',
                      help="Base name for output files. Defaults to nls. This produces files like nls_phases and nls_delays. Already existing files will be overwritten.", metavar="OUTFILE")
    parser.add_argument("-n", "--ndim", action="store",dest="ndim",type=int,default=None,
                      help="Number of nonlinearly sampled dimensions. Optional, for sanity check.")
    parser.add_argument("-p","--numpoints",dest="numpoints",type=int,default=None,
                        help="Number of sampled points. Optional, for sanity check.")
    
    args = parser.parse_args()
    out = args.outfile
    sw = args.sw
    mi = args.mi
    ndim = args.ndim
    print "Input file: %s" %args.infile
    print "Output file base name: %s"%out
    if not sw or not mi:
        parser.error("You must enter sweep widths and maximum increments for each nonlinearly sampled dimension.")
    if ndim:
        if len(sw) != ndim:
            parser.error("Number of sweep widths supplied, %d, does not match the number of dimensions, %d."%(len(sw),ndim))
        if len(mi) != ndim:
            parser.error("Number of maximum increments supplied, %d, does not match the stated number of dimensions, %d."%(len(mi),ndim))
    else:
        if len(sw) == len(mi):
            ndim = len(sw)
        else:
            parser.error("Number of maximum increments supplied, %d, does not match the number of sweep widths supplied, %d."%(len(mi),len(sw)))
    print "Sweep widths of non-linearly sampled dimensions: %s"%sw
    print "Maximum increments of non-linearly sampled dimensions: %s"%mi


    # Read the schedule, complain about some more problems. If the schedule file is not in the right format, you will just have to deal. 
    openfile = open(args.infile,'r')
    pointlines = openfile.readlines()
    openfile.close()

    if '0' in pointlines[0]:
        print "Schedule file starts with 0: %s"%pointlines[0]
    else:
        parser.error("Schedule file does not start with 0: %s\nUse awk '{print $1-1,$2-1,$3-1}' to make the conversion. "%pointlines[0])

    firstpoint = pointlines[0].split()
    if len(firstpoint) != ndim:
        parser.error("Schedule file contains %d dimensions, which does not match the number of sweep widths supplied, %d."%(len(firstpoint),ndim))
    numpoints = args.numpoints
    if numpoints:
        if numpoints != len(pointlines):
            parser.error("Number of points in the schedule file, %d, does not match the number of points indicated, %d."%(len(pointlines),numpoints))
        else:
            gridsize = 1
            for num in mi:
                gridsize = gridsize*num
            percentage = 100*float(numpoints)/float(gridsize)
            print "Sampling density is %d of %d, or %.1f%%."%(numpoints,gridsize,percentage)

    # Calculate delay increments

    increments = [1/(2.0*x) for x in sw]
    increment_strings = [ '%.6f'%x for x in increments]
    increment_string = ','.join(increment_strings)
    print "The delays will be incremented by: %s."%increment_string


    # Generate the main delay file & main phase file
    write_delays_and_phases(out,pointlines,increments)


    # Generate the sampling schedules for planes
    dimensions = range(ndim)
    for dim in dimensions:
        filename = '%s_plane%d_sched'%(out,dim+1)
        maxincrement = mi[dim]
        openfile = open(filename,'w')
        planepointlines = []
        for line in range(maxincrement):
            pointline = ''
            for dimension in dimensions:
                if dimension == dim:
                    openfile.write('%d '%line)
                    pointline += '%d '%line
                else:
                    openfile.write('0 ')
                    pointline += '0 '
            planepointlines.append(pointline)
            openfile.write('\n')
        openfile.close()
        filenamebase = '%s_plane%d'%(out,dim+1)
        # Generate the delay and phase files for each plane
        write_delays_and_phases(filenamebase,planepointlines,increments)

    
    

# Execute everything
main()

