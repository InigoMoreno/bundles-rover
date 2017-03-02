#!/usr/bin/env ruby

require 'orocos'
require 'rock/bundle'
require 'readline'
include Orocos

# Initialize bundles to find the configurations for the packages
Bundles.initialize

$gps_last_position = 0

# Execute the task
Orocos::Process.run 'hdpr_unit_gps' do

    # Configure
    gps = TaskContext.get 'gps'
    Orocos.conf.apply(gps, ['HDPR', 'Netherlands', 'DECOS'], :override => true)
    gps.configure

    # Log
    Orocos.log_all_ports

    # Start
    gps.start
    
    Readline::readline("Press Enter to exit\n") do
    end
end 
