#!/usr/bin/env python

#
# Make a pretty histogram graph of cyclictest output.
# Uses matplotlib:  I wanted to try something besides gnuplot for once.
# 
# Written by Aaron Fabbri <ajfabbri@gmail.com> for Intel.
#

import sys
import re
import os

import numpy as np
import matplotlib

# Order matters here, we want to render graphs to .png
matplotlib.use("agg")
import matplotlib.pyplot as plt

# To get above dependencies, depending on your linux distro:
# yum install python-matplotlib

debug = True

def dprint(s) :
    if debug :print s 

def usage() :
    sys.exit(("Usage: %s <data-filename>.\n\t<data-filename> is output from"
        + " cyclictest -v") % sys.argv[0])

def parse_cyclictest(filename) :
    """ Reads output from cyclictest -v and returns a list of (n, c, v)
	    tuples, where n = task number, c = count, and v = latency value.
    """	
    data_re = re.compile("\s*([0-9]+)\:\s+([0-9]+)\:\s+([0-9]+)")
    output = []
    f = open(filename)
    for l in f.readlines() :
        m = data_re.match(l)
        if m:
            output.append((int(m.group(1)),
                int(m.group(2)),
                int(m.group(3))))

    dprint("Got %d data points" % len(output))
    return output


def main() :
    if len(sys.argv) != 2 :
        usage()

    infile = sys.argv[1]
    raw_data = parse_cyclictest(infile)
    # get a list of only the latency values

    # FYI http://docs.python.org/2/tutorial/controlflow.html#unpacking-argument-lists
    _, _, lat_vals = zip(*raw_data)

    lat_vals = np.array(lat_vals)
    (lmax, lmin, lave) = (np.max(lat_vals), np.min(lat_vals), np.mean(lat_vals))

    # create histogram
    fig = plt.figure()
    n, bins, patches = plt.hist(lat_vals, 100, facecolor="blue", histtype="stepfilled", log=True) 

    plt.xlabel("usec")
    plt.ylabel("Num samples")
    plt.title("Cyclictest latency (N=%d, ave %f, min %d, max %d)" % (len(lat_vals), lave, lmin, lmax))
    plt.grid(True)
    image_name = os.path.basename(infile).replace(".", "_") + ".png"
    fig.savefig(image_name)
    print "Wrote " + image_name

if __name__ == "__main__" :
    main()

# vim: ai ts=4 sts=4 et sw=4
