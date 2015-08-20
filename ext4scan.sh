#!/bin/bash
#WARNING: This script requires superuser level commands to complete, please
#         read my code carefully and confirm it is safe. It is provided AS-IS
#         with no warranty implied or otherwise. Feel free to use this in any
#         MIT-friendly way.

# This script uses filesystem blocks which usually do not match physical
# blocks, and is offset by the partition start block. In theory, this should
# work with any filesystem that debugfs returns sane results for icheck and
# ncheck. Span is for segmenting very large block ranges.

if [ "$2" == "" ]; then
	echo "Usage: target start [last] [span]"
	exit 1
fi
target=$1
block=$2

#check if target is a valid filesystem
if ! tune2fs -l $target ; then
	echo "${target} does not have a valid filesystem"
	exit 1
fi

if [ "$3" == "end" ]; then
	lastblock=$(tune2fs -l $target | grep "Block coun" | awk '{print $3}')
elif [ "$3" == "" ]; then
	lastblock=$block
else
	lastblock=$3
fi

if [ $[block] -gt $[lastblock] ]; then
	echo "Start block is after last block!"
	exit 1
fi

if [ "$4" == "" ]; then
	span=1000
else
	span=$4
fi
if [ "$5" == "trust_block_bitmap" ]; then
	echo "WARNING: Block bitmap is enabled, it is fast but unreliable"
	TRUST_BLOCK_BITMAP=1
fi

OLDDIR=$PWD
#this working dir should be a tmpfs mount
mkdir /run/ext4scan
rm /run/ext4scan/*
cd /run/ext4scan

until [ "$block" -gt "$lastblock" ]; do
	if [ $(($[block] + $[span])) -gt $[lastblock] ]
	then
		next=$[lastblock]
	else
		next=$(($[block]+$[span]))
	fi

	echo "Processing ${block}-${next}"
	for i in `seq $[block] $[next]`
	do
		echo "testb ${i}" >> cmdset
	done

	if [ TRUST_BLOCK_BITMAP == "1" ]; then
		debugfs $target -f cmdset | grep 'marked' | awk '{print $2}' \
			> blocklist

		rm cmdset
		cat blocklist | while read line; do
			echo "block marked in use: ${line}"
			echo "icheck ${line}" >> cmdset
		done
		rm blocklist
	else
		debugfs $target -f cmdset | grep 'marked' | \
			awk '{print "block marked in use: "$2}'
		rm cmdset
		for i in `seq $[block] $[next]`
		do
			echo "icheck ${i}" >> cmdset
		done
	fi
	
	if [ -e cmdset ]; then
		debugfs $target -f cmdset 2>/dev/null | grep -v '[a-zA-Z]' | \
			awk '{print $2}' | uniq > inodelist

		rm cmdset
		cat inodelist | while read line; do
			echo "inode found: ${line}"
			echo "ncheck ${line}" >> cmdset
		done
		rm inodelist
	fi
	
	if [ -e cmdset ]; then
		debugfs $target -f cmdset | grep "^[0-9]" | \
			sed 's/^[0-9]*.//' > tempmanifest
		echo "Files that use FS blocks ${block}-${next}:"
		cat tempmanifest
		# merge tempmanifest and manifest, then eliminate duplicates 
		# and resort
		cat manifest >> tempmanifest
		uniq tempmanifest | sort > manifest
	else
		echo "Nothing found in this block range"
	fi

	rm cmdset
	block=$(($[next] + 1))
done
cp manifest ${OLDDIR}/manifest
echo "File manifest can be found at ${OLDDIR}/manifest"
