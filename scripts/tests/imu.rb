#!/usr/bin/env ruby

require 'orocos'
require 'rock/bundle'
require 'readline'
include Orocos

# Initialize bundles to find the configurations for the packages
Bundles.initialize

# Execute the task
Orocos::Process.run 'imu' do

    # Configure
    imu_stim300 = TaskContext.get 'imu_stim300'
    Orocos.conf.apply(imu_stim300, ['default', 'HDPR', 'ESTEC', 'stim300_5g'], :override => true)
    imu_stim300.configure

    # Log
    logger_imu = Orocos.name_service.get 'imu_Logger'
    logger_imu.file = "imu.log"
    logger_imu.log(imu_stim300.inertial_sensors_out)
    logger_imu.log(imu_stim300.temp_sensors_out)
    logger_imu.log(imu_stim300.orientation_samples_out)
    logger_imu.log(imu_stim300.compensated_sensors_out)
    logger_imu.log(imu_stim300.packet_counter)
    logger_imu.start

    # Start
    imu_stim300.start
    
    Readline::readline("Press Enter to exit\n") do
    end
end 
