#!/usr/bin/env ruby

require 'orocos'
require 'rock/bundle'
require 'readline'
include Orocos

# Initialize bundles to find the configurations for the packages
Bundles.initialize

# Execute the task
Orocos::Process.run 'hdpr_unit_odometry' do

    # Configure
    # For odometry we need the transformation from imu to body
    imu_stim300 = TaskContext.get 'imu_stim300'
    Orocos.conf.apply(imu_stim300, ['default', 'HDPR', 'ESTEC', 'stim300_5g'], :override => true)
    imu_stim300.configure

    # For odometry we need information about the joint states
    # Not sure if i need the platform driver and the read_joint_dispatcher
    platform_driver = Orocos.name_service.get 'platform_driver'
    Orocos.conf.apply(platform_driver, ['default'], :override => true)
    platform_driver.configure
    
    read_joint_dispatcher = Orocos.name_service.get 'read_joint_dispatcher'
    Orocos.conf.apply(read_joint_dispatcher, ['reading'], :override => true)
    read_joint_dispatcher.configure
    
    # Finally, configure the skid odometry task
    skid_odometry = Orocos.name_service.get 'skid_odometry'
    Orocos.conf.apply(skid_odometry, ['default', 'HDPR'], :override => true)
    skid_odometry.configure
    
    # Connections
    platform_driver.joints_readings.connect_to          read_joint_dispatcher.joints_readings
    read_joint_dispatcher.motors_samples.connect_to     skid_odometry.actuator_samples

    # Log all ports
    Orocos.log_all_ports

    # Start
    imu_stim300.start
    #platform_driver.start
    read_joint_dispatcher.start
    skid_odometry.start
    
    Readline::readline("Press Enter to exit\n") do
    end
end 
