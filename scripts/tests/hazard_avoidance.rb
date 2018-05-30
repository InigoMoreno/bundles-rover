#!/usr/bin/env ruby

require 'orocos'
require 'rock/bundle'
require 'readline'
require 'optparse'
#require 'vizkit'
include Orocos

options = {:bb2 => true, :v => true, :csc => true}

OptionParser.new do |opts|
  opts.banner = "Usage: start.rb [options]"
  opts.on('-v', '--vicon state', 'Enable vicon over gps') { |state| options[:v] = state }
  opts.on('-csc', '--customShutterController state', 'Enable/disable custom shutter controller') { |state| options[:csc] = state }
end.parse!

Bundles.initialize

Orocos::Process.run 'autonomy', 'navigation', 'control', 'unit_bb2', 'imu', 'gps', 'unit_gyro', 'unit_vicon', 'unit_shutter_controller', 'unit_hazard_detector', 'fdir' do

    joystick = Orocos.name_service.get 'joystick'
    Orocos.conf.apply(joystick, ['default'], :override => true)
    begin
        joystick.configure
    rescue
        abort("Cannot configure the joystick, is the dongle connected to HDPR?")
    end

    # Configure the control packages
    motion_translator = Orocos.name_service.get 'motion_translator'
    Orocos.conf.apply(motion_translator, ['hdpr'], :override => true)
    motion_translator.configure

    locomotion_control = Orocos.name_service.get 'locomotion_control'
    Orocos.conf.apply(locomotion_control, ['hdpr'], :override => true)
    locomotion_control.configure

    command_joint_dispatcher = Orocos.name_service.get 'command_joint_dispatcher'
    Orocos.conf.apply(command_joint_dispatcher, ['hdpr_commanding'], :override => true)
    command_joint_dispatcher.configure

    platform_driver = Orocos.name_service.get 'platform_driver'
    Orocos.conf.apply(platform_driver, ['hdpr'], :override => true)
    platform_driver.configure

    read_joint_dispatcher = Orocos.name_service.get 'read_joint_dispatcher'
    Orocos.conf.apply(read_joint_dispatcher, ['hdpr_reading'], :override => true)
    read_joint_dispatcher.configure

    imu_stim300 = TaskContext.get 'imu_stim300'
    Orocos.conf.apply(imu_stim300, ['default', 'HDPR', 'ESTEC', 'stim300_5g'], :override => true)
    imu_stim300.configure
    
    fdir = TaskContext.get 'fdir'
    Orocos.conf.apply(fdir, ['exoter'], :override => true)
    fdir.configure

    if options[:v] == false
        gps = TaskContext.get 'gps'
        Orocos.conf.apply(gps, ['HDPR', 'Netherlands', 'DECOS'], :override => true)
        gps.configure
    
        gps_heading = TaskContext.get 'gps_heading'
        Orocos.conf.apply(gps_heading, ['default'], :override => true)
        gps_heading.configure
    else
        vicon = TaskContext.get 'vicon'
        Orocos.conf.apply(vicon, ['default','hdpr'], :override => true)
        vicon.configure
    end

    puts "Starting BB2"

    camera_firewire_bb2 = TaskContext.get 'camera_firewire_bb2'
    Orocos.conf.apply(camera_firewire_bb2, ['exoter_bb2','egp_bb2_id'], :override => true)
    camera_firewire_bb2.configure

    camera_bb2 = TaskContext.get 'camera_bb2'
    Orocos.conf.apply(camera_bb2, ['egp_bb2'], :override => true)
    camera_bb2.configure

    stereo_bb2 = TaskContext.get 'stereo_bb2'
    Orocos.conf.apply(stereo_bb2, ['egp_bb2'], :override => true)
    stereo_bb2.configure

    # TO BE DECIDED IF SHUTTER CONTROLLER IS NEEDED OUTDOORS
    #shutter_controller_bb2 = Orocos.name_service.get 'shutter_controller'
    #Orocos.conf.apply(shutter_controller_bb2, ['default'], :override => true)
    #shutter_controller_bb2.configure

    # Setup Waypoint_navigation
    waypoint_navigation = Orocos.name_service.get 'waypoint_navigation'
    Orocos.conf.apply(waypoint_navigation, ['hdpr_lab'], :override => true)
    waypoint_navigation.configure

    # Setup command arbiter
    command_arbiter = Orocos.name_service.get 'command_arbiter'
    Orocos.conf.apply(command_arbiter, ['default'], :override => true)
    command_arbiter.configure

    gyro = TaskContext.get 'dsp1760'
    Orocos.conf.apply(gyro, ['default'], :override => true)
    gyro.configure

    # Hazard Detector
    hazard_detector = Orocos.name_service.get 'hazard_detector'
    Orocos.conf.apply(hazard_detector, ['default'], :override => true)
    hazard_detector.configure

    # Path Planner
    path_planner = Orocos.name_service.get 'path_planner'
    path_planner.keep_old_waypoints = true
    Orocos.conf.apply(path_planner, ['hdpr','prl'], :override => true)
    path_planner.configure
    puts "done"

    # Configure the connections between the components
    joystick.raw_command.connect_to                     motion_translator.raw_command
    joystick.raw_command.connect_to                     command_arbiter.raw_command

    motion_translator.motion_command.connect_to         command_arbiter.joystick_motion_command
    waypoint_navigation.motion_command.connect_to       command_arbiter.follower_motion_command
    command_arbiter.motion_command.connect_to           locomotion_control.motion_command

    locomotion_control.joints_commands.connect_to       command_joint_dispatcher.joints_commands
    command_joint_dispatcher.motors_commands.connect_to platform_driver.joints_commands
    platform_driver.joints_readings.connect_to          read_joint_dispatcher.joints_readings
    read_joint_dispatcher.motors_samples.connect_to     locomotion_control.joints_readings

    camera_firewire_bb2.frame.connect_to                camera_bb2.frame_in
    #camera_firewire_bb2.frame.connect_to                shutter_controller_bb2.frame
    #camera_firewire_bb2.shutter_value.connect_to        shutter_controller_bb2.shutter_value

    camera_bb2.left_frame.connect_to                    stereo_bb2.left_frame
    camera_bb2.right_frame.connect_to                   stereo_bb2.right_frame

    # Hazard Detector Inputs
    stereo_bb2.left_frame_sync.connect_to               hazard_detector.camera_frame
    stereo_bb2.distance_frame.connect_to                hazard_detector.distance_frame

    # Hazard Detector Outputs
    waypoint_navigation.trajectory_status.connect_to    fdir.trajectory_status
    imu_stim300.orientation_samples_out.connect_to      fdir.attitude
    platform_driver.error_in_motor.connect_to           fdir.error_in_motor
    hazard_detector.hazard_detected.connect_to          fdir.hazard_detected
    fdir.fault_detected.connect_to                      command_arbiter.fault_detected
    #fdir.fdir_state            ->>> Monitor from rock-display

    # Path Planner Outputs
    path_planner.trajectory.connect_to	                waypoint_navigation.trajectory

    # Waypoint navigation and Path Planner inputs:
    if options[:v] == false
        gps.pose_samples.connect_to                         gps_heading.gps_pose_samples
        gps.raw_data.connect_to                             gps_heading.gps_raw_data
        gps_heading.pose_samples_out.connect_to             waypoint_navigation.pose
        gps_heading.pose_samples_out.connect_to             path_planner.pose
        imu_stim300.orientation_samples_out.connect_to      gps_heading.imu_pose_samples
        gyro.orientation_samples.connect_to                 gps_heading.gyro_pose_samples
        command_arbiter.motion_command.connect_to           gps_heading.motion_command
        puts "using gps"
    else
        vicon.pose_samples.connect_to                       waypoint_navigation.pose
        vicon.pose_samples.connect_to                       path_planner.pose
        puts "using vicon"
    end

    # Start the components
    platform_driver.start
    read_joint_dispatcher.start
    command_joint_dispatcher.start
    locomotion_control.start
    command_arbiter.start
    motion_translator.start
    joystick.start
    imu_stim300.start
    gyro.start
    fdir.start
    if options[:v] == false
        gps.start
        gps_heading.start
    else
        vicon.start
    end
    camera_bb2.start
    camera_firewire_bb2.start
    stereo_bb2.start
    #shutter_controller_bb2.start
    if options[:v] == false
        # Race condition with internal gps_heading states. This check is here to only trigger the
        # trajectoryGen when the pose has been properly initialised. Otherwise the trajectory is set wrong.
        puts "Move rover forward to initialise the gps_heading component"
        while gps_heading.ready == false
           sleep 1
        end
        puts "GPS heading calibration done"
    end
    hazard_detector.start

    waypoint_navigation.start

    Readline::readline("Press ENTER to send goal pose to planner\n")

    #goal.start
    goal_writer = ares_planner.goalWaypoint.writer
    goal = Types::Base::Waypoint.new()
    if options[:v] == false
        goal.position[0] = 85.00
        goal.position[1] = 80.00
    else
        goal.position[0] = 6.00
        goal.position[1] = 3.00
    end
    goal.position[2] = 0.00
    goal.heading = 0.00
    goal_writer.write(goal)

    Readline::readline("Press Enter to exit\n") do
    end
end
