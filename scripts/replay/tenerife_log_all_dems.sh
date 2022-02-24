#!/bin/bash

set +e
# Set the dataset path here
dataset=/media/heimdal/Dataset1

# Go through all of the day/traverse folders
for day in $dataset/*June; do
    for traverse in $day/Traverse/*; do

        save_dir=$dataset/processed/${traverse#$dataset/}
        echo $save_dir
        
        # As some files were outdated, call rock-convert to update them (if they haven't been updated yet)
        if [ ! -f $traverse/updated/waypoint_navigation.log ]; then
            rock-convert $traverse/waypoint_navigation.log -o $traverse/updated/
        fi

        # If it is not yet processed (file does not exist), process it
        if [ ! -f $dataset/processed/${traverse#$day/Traverse/}.npz ]; then

            # Call tenerife_log_dems.rb (which runs ga_slam on the logs), see the comments in there
            ruby tenerife_log_dems.rb $traverse

            # Just in case kill orogen and restart the omniorb server
            sleep 5
            pkill -9 orogen
            sudo /etc/init.d/omniorb4-nameserver stop
            sudo rm -f /var/lib/omniorb/*
            sudo /etc/init.d/omniorb4-nameserver start
            sleep 5

            # Call dem_to_python.py (which transforms the logs to python file)
            python3 dem_to_python.py ${traverse#$dataset}/

            sudo rm -r $save_dir
        fi

    done
done