#!/usr/bin/env ruby

require 'orocos'
require 'rock/bundle'
require 'readline'
include Orocos

# Initialize bundles to find the configurations for the packages
Bundles.initialize

# Execute the task
Orocos::Process.run 'hdpr_pancam' do
    # Get the task contexts
    joystick = Orocos.name_service.get 'joystick'
    ptu_directedperception = Orocos.name_service.get 'ptu_directedperception'
    pancam_panorama = Orocos.name_service.get 'pancam_panorama'
    pancam_left = Orocos.name_service.get 'pancam_left'
    pancam_right = Orocos.name_service.get 'pancam_right'
    pancam_stereo = Orocos.name_service.get 'pancam_stereo'
    
    Orocos.conf.apply(ptu_directedperception, ['default'], :override => true)
    ptu_directedperception.configure
    Orocos.conf.apply(pancam_left, ['grashopper2_left'], :override => true)
    pancam_left.configure
    Orocos.conf.apply(pancam_right, ['grashopper2_right'], :override => true)
    pancam_right.configure
    Orocos.conf.apply(pancam_stereo, ['panCam'], :override => true)
    pancam_stereo.configure

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
    
    # Immediately enable
    pancam_panorama.configure
    
    # Connect the cameras to the stereo component
    pancam_left.frame.connect_to pancam_stereo.left_frame
    pancam_right.frame.connect_to pancam_stereo.right_frame
    # For feedback connect the PTU angles to motion translator
    pancam_panorama.pan_angle_in.connect_to ptu_directedperception.pan_angle
    pancam_panorama.tilt_angle_in.connect_to ptu_directedperception.tilt_angle
    # Connect the motion translator to the PTU control
    pancam_panorama.pan_angle_out.connect_to ptu_directedperception.pan_set
    pancam_panorama.tilt_angle_out.connect_to ptu_directedperception.tilt_set
    
    # The joystick enables the PanCam panorama mode
    joystick.raw_command.connect_to pancam_panorama.raw_command
    
    # Link the stereo task to PanCam so it would save only the relevant images
    pancam_stereo.left_frame_sync.connect_to pancam_panorama.left_frame_in
    pancam_stereo.right_frame_sync.connect_to pancam_panorama.right_frame_in
    
    # Only log output ports of pancam_panorama component, exclude the pancam position output as it is not useful
    pancam_panorama.log_all_ports(exclude_ports: /_angle_out$/)
    
    # Start the packages
    pancam_left.start
    pancam_right.start
    pancam_stereo.start
    ptu_directedperception.start
    pancam_panorama.start
    joystick.start
    
    Readline::readline("Press Enter to exit\n") do
    end
end

