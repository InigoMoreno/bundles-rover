#!/usr/bin/env ruby

require 'orocos'
require 'rock/bundle'
require 'readline'
include Orocos

# Initialize bundles to find the configurations for the packages
Bundles.initialize

# Execute the task
Orocos::Process.run 'hdpr_unit_control' do
    
    locomotion_control = Orocos.name_service.get 'locomotion_control'
    Orocos.conf.apply(locomotion_control, ['default'], :override => true)
    locomotion_control.configure
    
    command_joint_dispatcher = Orocos.name_service.get 'command_joint_dispatcher'
    Orocos.conf.apply(command_joint_dispatcher, ['commanding'], :override => true)
    command_joint_dispatcher.configure
    
    platform_driver = Orocos.name_service.get 'platform_driver'
    Orocos.conf.apply(platform_driver, ['default'], :override => true)
    platform_driver.configure
    
    read_joint_dispatcher = Orocos.name_service.get 'read_joint_dispatcher'
    Orocos.conf.apply(read_joint_dispatcher, ['reading'], :override => true)
    read_joint_dispatcher.configure

    # Log
    #Orocos.log_all_ports
    
    # Connect
    locomotion_control.joints_commands.connect_to command_joint_dispatcher.joints_commands
    command_joint_dispatcher.motors_commands.connect_to platform_driver.joints_commands
    platform_driver.joints_readings.connect_to read_joint_dispatcher.joints_readings
    read_joint_dispatcher.motors_samples.connect_to locomotion_control.joints_readings
    
    # Start
    platform_driver.start
    read_joint_dispatcher.start
    command_joint_dispatcher.start
    locomotion_control.start
    
    # Get a writer instance for the locomotion control
    writer_locomotion_control = locomotion_control.motion_command.writer
    
    while true
        locomotion_command = writer_locomotion_control.new_sample
        locomotion_command.translation = 0.1
        locomotion_command.rotation = 0.0
        writer_locomotion_control.write(locomotion_command)
        sleep 10
        locomotion_command = writer_locomotion_control.new_sample
        locomotion_command.translation = 0.0
        locomotion_command.rotation = 0.0
        writer_locomotion_control.write(locomotion_command)
        sleep 10
    end
    
    Readline::readline("Press Enter to exit\n") do
    end
end 
