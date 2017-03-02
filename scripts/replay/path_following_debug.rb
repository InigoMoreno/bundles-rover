#!/usr/bin/env ruby

require 'orocos'
require 'rock/bundle'
require 'vizkit'
include Orocos

# Initialize bundles to find the configurations for the packages
Bundles.initialize

# Execute the task
Orocos::Process.run 'hdpr_imu', 'hdpr_gps' do

    # Connect the tasks to the logs
    if ARGV.size == 1 then
        log_replay = Orocos::Log::Replay.open(ARGV[0] + "gps.log", ARGV[0] + "imu.log")
    end
    
    control = Vizkit.control log_replay
    control.speed = 1
    
    Vizkit.exec
end 
