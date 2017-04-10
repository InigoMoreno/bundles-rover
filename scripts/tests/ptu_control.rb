#!/usr/bin/env ruby

require 'orocos'
require 'rock/bundle'
require 'readline'
include Orocos

# Initialize bundles to find the configurations for the packages
Bundles.initialize

# Execute the task
Orocos::Process.run 'hdpr_unit_control' do

    # Configure
    joystick = Orocos.name_service.get 'joystick'
    joystick.device = "/dev/input/js0"
    begin
        joystick.configure
    rescue
        abort("Cannot configure the joystick, is the dongle connected to HDPR?")
    end
    
    motion_translator = Orocos.name_service.get 'motion_translator'
    motion_translator.configure
    
    ptu_directedperception = Orocos.name_service.get 'ptu_directedperception'
    Orocos.conf.apply(ptu_directedperception, ['default'], :override => true)
    ptu_directedperception.configure

    # Connect
    joystick.raw_command.connect_to motion_translator.raw_command

    motion_translator.ptu_pan_angle.connect_to ptu_directedperception.pan_set
    motion_translator.ptu_tilt_angle.connect_to ptu_directedperception.tilt_set
    
    # Start
    ptu_directedperception.start
    motion_translator.start
    joystick.start
    
    Readline::readline("Press Enter to exit\n") do
    end
end 
