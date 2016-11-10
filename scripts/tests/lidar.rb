#!/usr/bin/env ruby

require 'orocos'
require 'vizkit'
require 'rock/bundle'
require 'readline'
include Orocos

# Initialize bundles to find the configurations for the packages
Bundles.initialize

# Execute the task
Orocos::Process.run 'velodyne_lidar::LaserScanner' => 'velodyne_lidar' do
    velodyne_lidar = TaskContext.get 'velodyne_lidar'
    Orocos.conf.apply(velodyne_lidar, ['default'], :override => true)
    velodyne_lidar.configure

    # Log all ports
    Orocos.log_all_ports

    velodyne_lidar.start
    
    Readline::readline("Press Enter to exit\n") do
    end
end 
