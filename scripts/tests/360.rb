#!/usr/bin/env ruby

require 'orocos'
require 'rock/bundle'
require 'readline'
include Orocos

# Initialize bundles to find the configurations for the packages
Bundles.initialize

# Execute the task
Orocos::Process.run 'hdpr_unit_360' do
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
    
    ptu_directedperception = Orocos.name_service.get 'ptu_directedperception'
    Orocos.conf.apply(ptu_directedperception, ['default'], :override => true)
    ptu_directedperception.configure
    
    pancam_left = Orocos.name_service.get 'pancam_left'
    Orocos.conf.apply(pancam_left, ['grashopper2_left'], :override => true)
    pancam_left.configure
    
    pancam_right = Orocos.name_service.get 'pancam_right'
    Orocos.conf.apply(pancam_right, ['grashopper2_right'], :override => true)
    pancam_right.configure
    
    pancam_360 = Orocos.name_service.get 'pancam_360'
    Orocos.conf.apply(pancam_360, ['default'], :override => true)
    pancam_360.configure
    
    # Configure all the connections between the components
    joystick.raw_command.connect_to pancam_360.raw_command
    
    # For feedback connect the PTU angles to the pancam_360
    pancam_360.pan_angle_in.connect_to ptu_directedperception.pan_angle
    pancam_360.tilt_angle_in.connect_to ptu_directedperception.tilt_angle
    # Connect the motion translator to the PTU control
    pancam_360.pan_angle_out.connect_to ptu_directedperception.pan_set
    pancam_360.tilt_angle_out.connect_to ptu_directedperception.tilt_set
    
    pancam_left.frame.connect_to pancam_360.left_frame_in
    pancam_right.frame.connect_to pancam_360.right_frame_in
    
    pancam_360.log_all_ports

    # Start the components
    pancam_left.start
    pancam_right.start
    ptu_directedperception.start
    pancam_360.start
    joystick.start
    
    Readline::readline("Press Enter to exit\n") do
    end
end 
