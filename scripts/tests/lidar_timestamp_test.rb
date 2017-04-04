#!/usr/bin/env ruby

require 'orocos'
require 'rock/bundle'
require 'readline'
include Orocos

# Initialize bundles to find the configurations for the packages
Bundles.initialize

# Execute the task
Orocos::Process.run 'hdpr_unit_lidar', 'hdpr_unit_shutter_controller' do

    # Configure
    pancam_right = Orocos.name_service.get 'pancam_right'
    Orocos.conf.apply(pancam_right, ['grashopper2_right'], :override => true)
    pancam_right.configure
    
    shutter_controller = Orocos.name_service.get 'shutter_controller'
    shutter_controller.configure

    velodyne_lidar = TaskContext.get 'velodyne_lidar'
    Orocos.conf.apply(velodyne_lidar, ['default'], :override => true)
    velodyne_lidar.configure

    # Log
    Orocos.log_all
    #camera_firewire_bb3.log_all_ports
    
    # Connect
    pancam_right.frame.connect_to shutter_controller.frame
    pancam_right.shutter_value.connect_to shutter_controller.shutter_value
    
    # Start
    pancam_right.start
    shutter_controller.start
    velodyne_lidar.start

    Readline::readline("Press Enter to exit\n") do
    end
end 
