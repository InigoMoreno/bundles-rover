#!/usr/bin/env ruby

require 'orocos'
require 'rock/bundle'
require 'readline'
include Orocos

# Initialize bundles to find the configurations for the packages
Bundles.initialize

$last_gps_position = 0
$distance = 0

# Execute the task
Orocos::Process.run do

    # Configure
    gps = TaskContext.get 'gps_heading'
    #Orocos.conf.apply(gps_heading, ['default'], :override => true)
    #gps_heading.configure

    # Log
    #Orocos.log_all_ports

    # Start
    #gps_heading.start
    
    reader_gps_position = gps.heading.reader
    
    while true
        sample = reader_gps_position.read_new
        if sample
            # Initialise GPS position
            if $last_gps_position == 0
                $last_gps_position = sample
            end
            
            # Evaluate distance from last position
            x = sample.position[0] - $last_gps_position.position[0]
            y = sample.position[1] - $last_gps_position.position[1]
            $distance = Math.sqrt(x*x + y*y)
            
            puts $distance
            
            if $distance > 5
                $last_gps_position = sample
            end
        end
    end
    
    Readline::readline("Press Enter to exit\n") do
    end
end 
