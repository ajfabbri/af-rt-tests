#!/bin/bash

if [ `whoami` != "root" ]
then
	echo "Please run as root.. Exiting"
	exit
fi

ITER=200000
if [ ! -z "$1" ]
then
	ITER=$1
fi
INTERVAL=1000

#NUMAINST=/mnt/adrive/fabbri/Dev/numactl-2.0.9-rc3/install
#export LD_LIBRARY_PATH=$NUMAINST/lib64
outname=`date +%s`
outname="g-ct-${outname}.out"
outname=iso-$outname
cmd="taskset -c 1-3 cyclictest -l$ITER -i$INTERVAL  -q -p90 -a 1-3 -m -n -v"

echo "Starting $cmd"
uname -a >$outname
echo "# $cmd" >> $outname
$cmd >> $outname
