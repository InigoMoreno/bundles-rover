#!/usr/bin/env ruby

require 'orocos'
require 'rock/bundle'
require 'readline'
#require 'vizkit'
include Orocos

# Initialize bundles to find the configurations for the packages
Bundles.initialize

# Execute the task
Orocos::Process.run 'hdpr_control', 'hdpr_pancam', 'hdpr_lidar', 'hdpr_tof', 'hdpr_bb2', 'hdpr_bb3', 'hdpr_imu', 'hdpr_gps' do
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
    
    # Configure the sensor packages
    velodyne_lidar = TaskContext.get 'velodyne_lidar'
    Orocos.conf.apply(velodyne_lidar, ['default'], :override => true)
    velodyne_lidar.configure
    
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
    Orocos.conf.apply(camera_firewire_bb2, ['bumblebee2'], :override => true)
    camera_firewire_bb2.configure
    
    camera_bb2 = TaskContext.get 'camera_bb2'
    Orocos.conf.apply(camera_bb2, ['default'], :override => true)
    camera_bb2.configure

    camera_firewire_bb3 = TaskContext.get 'camera_firewire_bb3'
    Orocos.conf.apply(camera_firewire_bb3, ['bumblebee3'], :override => true)
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
    
    # Configure the processing packages
    pancam_panorama = Orocos.name_service.get 'pancam_panorama'
    Orocos.conf.apply(pancam_panorama, ['default'], :override => true)
    pancam_panorama.configure
    
    # Configure the connections between the components
    joystick.raw_command.connect_to                     pancam_panorama.raw_command
    joystick.raw_command.connect_to                     motion_translator.raw_command
    motion_translator.motion_command.connect_to         locomotion_control.motion_command
    locomotion_control.joints_commands.connect_to       command_joint_dispatcher.joints_commands
    command_joint_dispatcher.motors_commands.connect_to platform_driver.joints_commands
    platform_driver.joints_readings.connect_to          read_joint_dispatcher.joints_readings
    read_joint_dispatcher.motors_samples.connect_to     locomotion_control.joints_readings
    camera_firewire_bb2.frame.connect_to                camera_bb2.frame_in
    camera_firewire_bb3.frame.connect_to                camera_bb3.frame_in
    pancam_panorama.pan_angle_in.connect_to             ptu_directedperception.pan_angle
    pancam_panorama.tilt_angle_in.connect_to            ptu_directedperception.tilt_angle
    pancam_panorama.pan_angle_out.connect_to            ptu_directedperception.pan_set
    pancam_panorama.tilt_angle_out.connect_to           ptu_directedperception.tilt_set
    pancam_left.frame.connect_to                        pancam_panorama.left_frame_in
    pancam_right.frame.connect_to                       pancam_panorama.right_frame_in
    
    # Define loggers
    logger_control = Orocos.name_service.get 'hdpr_control_Logger'
    logger_control.file = "control.log"
    logger_control.log(platform_driver.joints_readings)
    
    logger_pancam = Orocos.name_service.get 'hdpr_pancam_Logger'
    logger_pancam.file = "pancam.log"
    logger_pancam.log(pancam_panorama.frame)
    
    logger_bb2 = Orocos.name_service.get 'hdpr_bb2_Logger'
    logger_bb2.file = "bb2.log"
    logger_bb2.log(camera_firewire_bb2.frame)
    
    logger_bb3 = Orocos.name_service.get 'hdpr_bb3_Logger'
    logger_bb3.file = "bb3.log"
    logger_bb3.log(camera_firewire_bb3.frame)
    
    logger_tof = Orocos.name_service.get 'hdpr_tof_Logger'
    logger_tof.file = "tof.log"
    logger_tof.log(tofcamera_mesasr.distance_frame)
    logger_tof.log(tofcamera_mesasr.ir_frame)
    logger_tof.log(tofcamera_mesasr.tofscan)
    
    logger_lidar = Orocos.name_service.get 'hdpr_lidar_Logger'
    logger_lidar.file = "lidar.log"
    logger_lidar.log(velodyne_lidar.ir_frame)
    logger_lidar.log(velodyne_lidar.laser_scans)
    logger_lidar.log(velodyne_lidar.range_frame)
    
    logger_gps = Orocos.name_service.get 'hdpr_gps_Logger'
    logger_gps.file = "gps.log"
    logger_gps.log(gps.pose_samples)
    logger_gps.log(gps.time)
    
    logger_imu = Orocos.name_service.get 'hdpr_imu_Logger'
    logger_imu.file = "imu.log"
    logger_imu.log(imu_stim300.inertial_sensors_out)
    logger_imu.log(imu_stim300.temp_sensors_out)
    logger_imu.log(imu_stim300.orientation_samples_out)
    
    #Orocos.log_all_ports
    
    # Start loggers
    logger_control.start
    logger_pancam.start
    logger_bb2.start
    logger_bb3.start
    logger_tof.start
    logger_lidar.start
    logger_gps.start
    logger_imu.start

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
    
    # Show camera output
    #Vizkit.display pancam_panorama.left_frame_out
    #Vizkit.display pancam_panorama.right_frame_out
    #Vizkit.display camera_bb2.left_frame
    #Vizkit.display camera_bb3.left_frame
    #Vizkit.display tofcamera_mesasr.distance_frame
    #Vizkit.display velodyne_lidar.ir_interp_frame
    
    #Vizkit.exec
    
    # Not needed when Vizkit is running
    Readline::readline("Press Enter to exit\n") do
    end
end 
