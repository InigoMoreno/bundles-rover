#!/usr/bin/env ruby

require 'orocos'
require 'rock/bundle'
require 'readline'
include Orocos

# Initialize bundles to find the configurations for the packages
Bundles.initialize

# Execute the task
Orocos::Process.run 'control' do

    platform_driver = Orocos.name_service.get 'platform_driver_marta'
    Orocos.conf.apply(platform_driver, ['default'], :override => true)
    platform_driver.configure

    # Log
    #Orocos.log_all_ports
    #platform_driver.log_all_ports
    #pancam_panorama.log_all_ports

    # Connect
    #command_joint_dispatcher.motors_commands.connect_to   platform_driver.joints_commands
    #platform_driver.joints_readings.connect_to            read_joint_dispatcher.joints_readings

    # Start
    platform_driver.start

    Readline::readline("Press Enter to exit\n") do
    end
end
