#!/usr/bin/env ruby

require 'orocos'
require 'rock/bundle'
require 'readline'
include Orocos

# Initialize bundles to find the configurations for the packages
Bundles.initialize

Bundles.transformer.load_conf(Bundles.find_file('config', 'transforms_scripts.rb'))

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
    
    # Finally, configure the threed odometry task
    threed_odometry = Orocos.name_service.get 'threed_odometry'
    Orocos.conf.apply(threed_odometry, ['default', 'HDPR'], :override => true)
    Bundles.transformer.setup(threed_odometry)
    threed_odometry.configure
    
    # Connections
    platform_driver.joints_readings.connect_to          read_joint_dispatcher.joints_readings
    read_joint_dispatcher.joints_samples.connect_to     threed_odometry.joints_samples
    imu_stim300.orientation_samples_out.connect_to	threed_odometry.orientation_samples

    # Log all ports
    Orocos.log_all_ports

    # Start
    imu_stim300.start
    #platform_driver.start
    read_joint_dispatcher.start
    #threed_odometry.start
    
    Readline::readline("Press Enter to exit\n") do
    end
end 
