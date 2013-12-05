#!/bin/bash

if [ `whoami` != "root" ]
then
	echo "Please run as root.. Exiting"
	exit
fi

ITER=8000
if [ ! -z "$1" ]
then
	ITER=$1
fi
INTERVAL=700

for i in 2 20 400 800 1000
do
	INTERVAL=$i
	cmd="taskset -c 1-3 cyclictest -l$ITER -i$INTERVAL  -q -p90 -a 1-3 -m -n -t3"

#	echo "Starting $cmd"
	$cmd | grep -v "^\#"
done

