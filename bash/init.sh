#!/bin/bash
# code to set up the repo

cd ../

mkdir data figures scripts R

for folder in data figures scripts
do
	echo "files related to $folder" > $folder/_description.txt
done
