#!/usr/bin/env ruby

require 'orocos'
require 'rock/bundle'
require 'readline'
#require 'vizkit'
include Orocos

# Initialize bundles to find the configurations for the packages
Bundles.initialize

# Distance to move between 360 picture taking
$distance_360_picture = 30

# Execute the task
Orocos::Process.run 'hdpr_control', 'hdpr_navigation' do
    joystick = Orocos.name_service.get 'joystick'
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
    
    # Configure the control packages
    motion_translator = Orocos.name_service.get 'motion_translator'
    motion_translator.configure

    # Setup command arbiter
    command_arbiter = Orocos.name_service.get 'command_arbiter'
    Orocos.conf.apply(command_arbiter, ['default'], :override => true)
    command_arbiter.configure
    
    # Configure the connections between the components
    joystick.raw_command.connect_to                     command_arbiter.raw_command
    motion_translator.motion_command.connect_to         command_arbiter.joystick_motion_command

    # Start the components
    motion_translator.start
    joystick.start
    command_arbiter.start
    
    Readline::readline("Press Enter to exit\n") do
    end
end 
