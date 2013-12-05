#!/bin/bash

if [ `whoami` != "root" ]
then
	echo "Please run as root.. Exiting"
	exit
fi

ITER=50000
if [ ! -z "$1" ]
then
	ITER=$1
fi
INTERVAL=1000

#NUMAINST=/mnt/adrive/fabbri/Dev/numactl-2.0.9-rc3/install
#export LD_LIBRARY_PATH=$NUMAINST/lib64
outname=`date +%s`
outname="quiet-${outname}.out"
cmd="taskset -c 1-3 cyclictest -l$ITER -i$INTERVAL  -q -p95 -a 1-3 -n -m"

echo "Starting $cmd"
#uname -a >$outname
#echo "# $cmd" >> $outname
$cmd
