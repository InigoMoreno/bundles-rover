#!/usr/bin/env ruby

require 'orocos'
require 'rock/bundle'
require 'readline'
include Orocos

# Initialize bundles to find the configurations for the packages
Bundles.initialize

# Execute the task
Orocos::Process.run 'hdpr_control' do
    # Get the task contexts
    joystick = Orocos.name_service.get 'joystick'
    motion_translator = Orocos.name_service.get 'motion_translator'
    locomotion_control = Orocos.name_service.get 'locomotion_control'
    platform_driver = Orocos.name_service.get 'platform_driver'
    command_joint_dispatcher = Orocos.name_service.get 'command_joint_dispatcher'
    read_joint_dispatcher = Orocos.name_service.get 'read_joint_dispatcher'
    ptu_directedperception = Orocos.name_service.get 'ptu_directedperception'

    # Set the joystick input
    joystick.device = "/dev/input/js0"
    
    # In case the dongle is not connected exit gracefully
    begin
        # Configure the joystick
        joystick.configure
    rescue
        # Abort the process as there is no joystick to get input from
        abort("Cannot configure the joystick, is the dongle connected to HDPR?")
    end
    
    # Configure the packages
    motion_translator.configure
    Orocos.conf.apply(locomotion_control, ['default'], :override => true)
    locomotion_control.configure
    Orocos.conf.apply(command_joint_dispatcher, ['commanding'], :override => true)
    command_joint_dispatcher.configure
    Orocos.conf.apply(platform_driver, ['default'], :override => true)
    platform_driver.configure
    Orocos.conf.apply(read_joint_dispatcher, ['reading'], :override => true)
    read_joint_dispatcher.configure
    Orocos.conf.apply(ptu_directedperception, ['default'], :override => true)
    ptu_directedperception.configure
    
    # Configure all the connections between the packages
    joystick.raw_command.connect_to motion_translator.raw_command
    motion_translator.motion_command.connect_to locomotion_control.motion_command
    locomotion_control.joints_commands.connect_to command_joint_dispatcher.joints_commands
    command_joint_dispatcher.motors_commands.connect_to platform_driver.joints_commands
    platform_driver.joints_readings.connect_to read_joint_dispatcher.joints_readings
    read_joint_dispatcher.motors_samples.connect_to locomotion_control.joints_readings
    
    # Connect the motion translator to the PTU control
    motion_translator.ptu_pan_angle.connect_to ptu_directedperception.pan_set
    motion_translator.ptu_tilt_angle.connect_to ptu_directedperception.tilt_set
    
    # For feedback connect the PTU angles to motion translator
    motion_translator.ptu_pan_angle_in.connect_to ptu_directedperception.pan_angle
    motion_translator.ptu_tilt_angle_in.connect_to ptu_directedperception.tilt_angle
    
    # Start the packages
    platform_driver.start
    read_joint_dispatcher.start
    command_joint_dispatcher.start
    locomotion_control.start
    ptu_directedperception.start
    motion_translator.start
    joystick.start
    
    Readline::readline("Press Enter to exit\n") do
    end
end 
