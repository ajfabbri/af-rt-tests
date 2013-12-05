#!/bin/bash

#
# Generate load which increases system latency and jitter.
# Stragegy is to do all of these things:
# 1. Exercise drivers and hardware.
# 2. Create a lot of threads/processes and do synchronization between them.
# 3. Create memory and I/O buffer pressure.
# 4. ...
#

# Some commands from Igno Molnar's script: https://lkml.org/lkml/2005/6/22/347

# Edit these for your environment -----
HOST_TO_PING=10.23.2.92


# end config section	 --------------

function die() {
	echo "Barfing: $1"
	exit
}

function check_commands() {
	for c in hackbench dd ping find du
	do
		if ! type "$c" > /dev/hull
		then
			die "Can't find command $c"
		fi
	done

}

function files_and_disks() {
	while true
	do
		nice dd if=/dev/zero of=/dev/null bs=1000 count=1000 > /dev/null 2>&1 || die "dd"
		dd if=/dev/zero of=bigfile bs=32900 count=100 > /dev/null 2>&1
		dd if=/dev/zero of=bigfile2 bs=500 count=10000 > /dev.null 2>&1
		sleep 0.007
		du /var > /dev/null
		find /usr -maxdepth 2 -type f -exec md5sum "{}" \; > /dev/null 
	done
}

function threads_and_wakeups() {
	while true
	do
		hackbench --datasize 1000 -l 1000 -g 10 -f 20 >/dev/null || die "hackbench"
		hackbench > /dev/null
		sleep 0.001
	done
}

function network_stack() {
	while true
	do
		ping -i 0.01 -l 10 -c1000 -q localhost > /dev/null &
		ping -i 0.01 -l 10 -c1000 -q $HOST_TO_PING > /dev/null
		sleep 0.002
	done
}

if [ `whoami` != "root" ]
then
	echo "Please run as root.. Exiting"
	exit
fi

check_commands
files_and_disks  &
threads_and_wakeups  &
network_stack & 

wait

