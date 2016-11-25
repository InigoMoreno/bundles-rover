#!/usr/bin/env ruby

require 'orocos'
require 'rock/bundle'
require 'readline'
include Orocos

# Initialize bundles to find the configurations for the packages
Bundles.initialize

# Execute the task
Orocos::Process.run 'hdpr_locomotion', 'hdpr_ptu', 'hdpr_vision', 'hdpr_sensors' do
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
    
    # Configure the packages
    motion_translator = Orocos.name_service.get 'motion_translator'
    motion_translator.configure
    
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
    
    ptu_directedperception = Orocos.name_service.get 'ptu_directedperception'
    Orocos.conf.apply(ptu_directedperception, ['default'], :override => true)
    ptu_directedperception.configure
    
    velodyne_lidar = TaskContext.get 'velodyne_lidar'
    Orocos.conf.apply(velodyne_lidar, ['default'], :override => true)
    velodyne_lidar.configure
    
    # SwissRanger SR4500 Mesa Time-of-Flight camera
    tofcamera_mesasr = TaskContext.get 'tofcamera_mesasr'
    Orocos.conf.apply(tofcamera_mesasr, ['default'], :override => true)
    tofcamera_mesasr.configure
    
    imu_stim300 = TaskContext.get 'imu_stim300'
    Orocos.conf.apply(imu_stim300, ['default', 'HDPR', 'ESTEC', 'stim300_5g'], :override => true)
    imu_stim300.configure
    
    gps = TaskContext.get 'gps'
    Orocos.conf.apply(gps, ['HDPR', 'Netherlands', 'ESTEC'], :override => true)
    gps.configure

    camera_firewire_bb2 = TaskContext.get 'camera_firewire_bb2'
    Orocos.conf.apply(camera_firewire_bb2, ['default'], :override => true)
    camera_firewire_bb2.configure
    
    camera_bb2 = TaskContext.get 'camera_bb2'
    Orocos.conf.apply(camera_bb2, ['default'], :override => true)
    camera_bb2.configure

    camera_firewire_bb3 = TaskContext.get 'camera_firewire_bb3'
    Orocos.conf.apply(camera_firewire_bb3, ['default'], :override => true)
    camera_firewire_bb3.configure
    
    camera_bb3 = TaskContext.get 'camera_bb3'
    Orocos.conf.apply(camera_bb3, ['default'], :override => true)
    camera_bb3.configure
    
    pancam_left = Orocos.name_service.get 'pancam_left'
    Orocos.conf.apply(pancam_left, ['grashopper2_left'], :override => true)
    pancam_left.configure
    
    pancam_right = Orocos.name_service.get 'pancam_right'
    Orocos.conf.apply(pancam_right, ['grashopper2_right'], :override => true)
    pancam_right.configure
    
    pancam_panorama = Orocos.name_service.get 'pancam_panorama'
    Orocos.conf.apply(pancam_panorama, ['default'], :override => true)
    pancam_panorama.configure
    
    # Configure all the connections between the components
    joystick.raw_command.connect_to pancam_panorama.raw_command
    joystick.raw_command.connect_to motion_translator.raw_command
    
    motion_translator.motion_command.connect_to locomotion_control.motion_command
    locomotion_control.joints_commands.connect_to command_joint_dispatcher.joints_commands
    command_joint_dispatcher.motors_commands.connect_to platform_driver.joints_commands
    platform_driver.joints_readings.connect_to read_joint_dispatcher.joints_readings
    read_joint_dispatcher.motors_samples.connect_to locomotion_control.joints_readings
    
    # Bumblebee cameras
    camera_firewire_bb2.frame.connect_to camera_bb2.frame_in
    camera_firewire_bb3.frame.connect_to camera_bb3.frame_in
    
    # For feedback connect the PTU angles to the pancam_panorama
    pancam_panorama.pan_angle_in.connect_to ptu_directedperception.pan_angle
    pancam_panorama.tilt_angle_in.connect_to ptu_directedperception.tilt_angle
    # Connect the motion translator to the PTU control
    pancam_panorama.pan_angle_out.connect_to ptu_directedperception.pan_set
    pancam_panorama.tilt_angle_out.connect_to ptu_directedperception.tilt_set
    
    pancam_left.frame.connect_to pancam_panorama.left_frame_in
    pancam_right.frame.connect_to pancam_panorama.right_frame_in
    
    # Log all important outputs
    platform_driver.log_all_ports
    camera_bb2.log_all_ports
    camera_bb3.log_all_ports
    pancam_panorama.log_all_ports
    velodyne_lidar.log_all_ports
    tofcamera_mesasr.log_all_ports
    imu_stim300.log_all_ports
    gps.log_all_ports
    #gyro.log_all_ports

    # Start the components
    platform_driver.start
    read_joint_dispatcher.start
    command_joint_dispatcher.start
    locomotion_control.start
    ptu_directedperception.start
    pancam_left.start
    pancam_right.start
    pancam_panorama.start
    motion_translator.start
    joystick.start
    velodyne_lidar.start
    tofcamera_mesasr.start
    imu_stim300.start
    gps.start
    camera_bb2.start
    camera_firewire_bb2.start
    camera_bb3.start
    camera_firewire_bb3.start
    
    Readline::readline("Press Enter to exit\n") do
    end
end 
