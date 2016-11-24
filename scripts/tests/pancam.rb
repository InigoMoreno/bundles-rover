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
    
    loc_cam = TaskContext.get 'loc_cam'
    camera_bb2 = TaskContext.get 'camera_bb2'
    loccam_stereo = TaskContext.get 'loccam_stereo'
    
    Orocos.conf.apply(ptu_directedperception, ['default'], :override => true)
    ptu_directedperception.configure
    Orocos.conf.apply(pancam_left, ['grashopper2_left'], :override => true)
    pancam_left.configure
    Orocos.conf.apply(pancam_right, ['grashopper2_right'], :override => true)
    pancam_right.configure
    Orocos.conf.apply(pancam_stereo, ['panCam'], :override => true)
    pancam_stereo.configure
    
    Orocos.conf.apply(loc_cam, ['default'], :override => true)
    loc_cam.configure
    Orocos.conf.apply(camera_bb2, ['default'], :override => true)
    camera_bb2.configure
    Orocos.conf.apply(loccam_stereo, ['locCam'], :override => true)
    loccam_stereo.configure

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
    Orocos.conf.apply(pancam_panorama, ['default'], :override => true)
    pancam_panorama.configure
    
    # Connect the cameras to the stereo component
    #pancam_left.frame.connect_to pancam_stereo.left_frame
    #pancam_right.frame.connect_to pancam_stereo.right_frame
    # For feedback connect the PTU angles to the pancam_panorama
    pancam_panorama.pan_angle_in.connect_to ptu_directedperception.pan_angle
    pancam_panorama.tilt_angle_in.connect_to ptu_directedperception.tilt_angle
    # Connect the motion translator to the PTU control
    pancam_panorama.pan_angle_out.connect_to ptu_directedperception.pan_set
    pancam_panorama.tilt_angle_out.connect_to ptu_directedperception.tilt_set
    
    # The joystick enables the PanCam panorama mode
    joystick.raw_command.connect_to pancam_panorama.raw_command
    
    # Link the stereo task to PanCam so it would save only the relevant images
    #pancam_stereo.left_frame_sync.connect_to pancam_panorama.left_frame_in
    #pancam_stereo.right_frame_sync.connect_to pancam_panorama.right_frame_in
    
    pancam_left.frame.connect_to pancam_panorama.left_frame_in
    pancam_right.frame.connect_to pancam_panorama.right_frame_in
    
    loc_cam.frame.connect_to camera_bb2.frame_in
    camera_bb2.left_frame.connect_to loccam_stereo.left_frame
    camera_bb2.right_frame.connect_to loccam_stereo.right_frame
    
    # Only log BB2 left and right frames and the PanCam cameras when they have stabilised
    Orocos.log_all_ports(exclude_ports: /state$|pan_angle|tilt_angle|^frame|command|disparity|distance|_sync$|^io_|samples|debug|features|raw/)
    
    # Start the packages
    pancam_left.start
    pancam_right.start
    pancam_stereo.start
    ptu_directedperception.start
    pancam_panorama.start
    joystick.start

    loc_cam.start
    camera_bb2.start
    loccam_stereo.start
    
    Readline::readline("Press Enter to exit\n") do
    end
end

