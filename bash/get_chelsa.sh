#!/bin/bash
cd ..
# code to get chelsa files
wget -P data/spatial/chelsa/ --no-host-directories --force-directories --input-file=data/spatial/chelsa/envidatS3paths.txt
