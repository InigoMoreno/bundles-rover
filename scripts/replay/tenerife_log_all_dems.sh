#!/bin/bash

set +e
dataset=/media/heimdal/Dataset1
for day in $dataset/*June; do
    for traverse in $day/Traverse/*; do
        save_dir=$dataset/processed/${traverse#$dataset/}
        echo $save_dir
        
        if [ ! -f $traverse/updated/waypoint_navigation.log ]; then
            rock-convert $traverse/waypoint_navigation.log -o $traverse/updated/
        fi

        if [ ! -f $dataset/processed/${traverse#$day/Traverse/}.npz ]; then
            ruby tenerife_log_dems.rb $traverse
            sleep 5
            pkill -9 orogen
            sudo /etc/init.d/omniorb4-nameserver stop
            sudo rm -f /var/lib/omniorb/*
            sudo /etc/init.d/omniorb4-nameserver start
            sleep 5

            python3 dem_to_python.py ${traverse#$dataset}/

            sudo rm -r $save_dir
        fi

    done
done