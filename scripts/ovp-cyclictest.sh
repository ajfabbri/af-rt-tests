#!/bin/bash

if [ `whoami` != "root" ]
then
	echo "Please run as root.. Exiting"
	exit
fi

NUMAINST=/mnt/adrive/fabbri/Dev/numactl-2.0.9-rc3/install
export LD_LIBRARY_PATH=$NUMAINST/lib64
outname=`date +%s`
outname="ct-${outname}.out"
taskset -c 9-15 cyclictest -l200000 -i700  -q -p80 -a 9-15 -m -v > iso-$outname
