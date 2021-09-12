#!/bin/bash
# code to set up the repo

cd ../

mkdir data figures scripts R supplement

for folder in data figures scripts supplement figure-scripts
do
	echo "files related to $folder" > $folder/_description.txt
    if [ $folder = "data" ]
    then
        cd $folder
        mkdir raw spatial results output
        for subdir in raw spatial results output
        do 
            echo "data related to $subdir" > $subdir/_description.txt
        done
        cd ..
    fi
done

echo "#ignore these files" > .gitignore
