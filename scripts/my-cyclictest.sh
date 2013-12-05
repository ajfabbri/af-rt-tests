#!/bin/bash

if [ `whoami` != "root" ]
then
	echo "Please run as root.. Exiting"
	exit
fi

outname=`date +%s`
outname="ct-${outname}.out"
rt-tests/cyclictest -l200000 -i700  -q -p80 --numa -m -v > numa-$outname
