#!/usr/bin/env ruby

require 'orocos'
require 'rock/bundle'
require 'readline'
include Orocos

# Initialize bundles to find the configurations for the packages
Bundles.initialize

# Execute the task
Orocos::Process.run 'hdpr_unit_lidar' do

    # Configure
    velodyne_lidar = TaskContext.get 'velodyne_lidar'
    Orocos.conf.apply(velodyne_lidar, ['default'], :override => true)
    velodyne_lidar.configure

    # Log
    Orocos.log_all_ports

    # Start
    velodyne_lidar.start
    
    Readline::readline("Press Enter to exit\n") do
    end
end 
