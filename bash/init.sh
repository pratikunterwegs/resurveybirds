#!/bin/bash
# code to set up the repo

mkdir data figures scripts R

for folder in data figures scripts supplement
do
	echo "files related to $folder" > $folder/_description.txt
    if [ $folder = "data" ]
    then
        cd $folder
        mkdir raw spatial results
        for subdir in raw spatial results
        do 
            echo "data related to $subdir" > $subdir/_description.txt
        done
        cd ..
    fi
done
