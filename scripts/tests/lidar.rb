#!/usr/bin/env ruby

require 'orocos'
require 'rock/bundle'
require 'readline'
include Orocos

# Initialize bundles to find the configurations for the packages
Bundles.initialize

# Execute the task
Orocos::Process.run 'unit_lidar' do

    # Configure
    velodyne_lidar = TaskContext.get 'velodyne_lidar'
    Orocos.conf.apply(velodyne_lidar, ['default'], :override => true)
    velodyne_lidar.configure
    
    #logger_lidar = Orocos.name_service.get 'unit_lidar_Logger'
    #logger_lidar.file = "lidar.log"
    #logger_lidar.log(velodyne_lidar.ir_frame)
    #logger_lidar.log(velodyne_lidar.laser_scans)
    #logger_lidar.log(velodyne_lidar.range_frame)
    #logger_lidar.log(velodyne_lidar.azimuth_frame)
    #logger_lidar.log(velodyne_lidar.velodyne_time)
    #logger_lidar.log(velodyne_lidar.accumulated_velodyne_time)
    #logger_lidar.log(velodyne_lidar.estimated_clock_offset)
    #logger_lidar.log(velodyne_lidar.velodyne_time)
    #logger_lidar.start

    # Start
    velodyne_lidar.start
    
    Readline::readline("Press Enter to exit\n") do
    end
end 
