#!/usr/bin/env ruby

require 'orocos'
require 'rock/bundle'
require 'readline'
include Orocos

# Initialize bundles to find the configurations for the packages
Bundles.initialize

# Execute the task
Orocos::Process.run 'hdpr_unit_bb3', 'hdpr_unit_imu' do

    # Configure
    camera_firewire_bb3 = TaskContext.get 'camera_firewire_bb3'
    Orocos.conf.apply(camera_firewire_bb3, ['bumblebee3'], :override => true)
    camera_firewire_bb3.configure

    camera_bb3 = TaskContext.get 'camera_bb3'
    Orocos.conf.apply(camera_bb3, ['default'], :override => true)
    camera_bb3.configure

    # Configure
    imu_stim300 = TaskContext.get 'imu_stim300'
    Orocos.conf.apply(imu_stim300, ['default', 'HDPR', 'ESTEC', 'stim300_5g'], :override => true)
    imu_stim300.configure

    # Log
    logger_bb3 = Orocos.name_service.get 'hdpr_unit_bb3_Logger'
    logger_bb3.file = "bb3.log"
    logger_bb3.log(camera_bb3.left_frame)
    logger_bb3.log(camera_bb3.center_frame)
    logger_bb3.log(camera_bb3.right_frame)
    logger_bb3.start
    
    logger_imu = Orocos.name_service.get 'hdpr_imu_Logger'
    logger_imu.file = "imu.log"
    logger_imu.log(imu_stim300.inertial_sensors_out)
    logger_imu.log(imu_stim300.temp_sensors_out)
    logger_imu.log(imu_stim300.orientation_samples_out)
    logger_imu.log(imu_stim300.compensated_sensors_out)
    logger_imu.start
    
    # Connect
    camera_firewire_bb3.frame.connect_to camera_bb3.frame_in
    camera_firewire_bb2.frame.connect_to camera_bb2.frame_in

    # Start
    camera_firewire_bb3.start
    camera_bb3.start
    imu_stim300.start
    
    Readline::readline("Press Enter to exit\n") do
    end
end 
