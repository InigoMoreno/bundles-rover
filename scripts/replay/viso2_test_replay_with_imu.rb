#!/usr/bin/env ruby

require 'orocos'
require 'rock/bundle'
require 'transformer/runtime'
require 'vizkit'
include Orocos

Bundles.initialize
Bundles.transformer.load_conf(Bundles.find_file('config', 'transforms_scripts.rb'))

Orocos::Process.run 'hdpr_unit_visual_odometry', 'hdpr_unit_bb2' do

    camera_bb2 = TaskContext.get 'camera_bb2'
    Orocos.conf.apply(camera_bb2, ['default'], :override => true)
    camera_bb2.configure
    
    visual_odometry = TaskContext.get 'viso2'
    Orocos.conf.apply(visual_odometry, ['bumblebee'], :override => true)
    Bundles.transformer.setup(visual_odometry)
    visual_odometry.configure

    extended_visual_odometry = TaskContext.get 'viso2_with_imu'
    extended_visual_odometry.configure
    
#    gps_heading2 = TaskContext.get 'gps_heading'
#    Orocos.conf.apply(gps_heading2, ['default'], :override => true)
#    gps_heading2.configure
    
    stereo_bb2 = TaskContext.get 'stereo_bb2'
    Orocos.conf.apply(stereo_bb2, ['hdpr_bb2'], :override => true)
    stereo_bb2.configure

    # Connect the tasks to the logs
    if ARGV.size == 1 then
        log_replay = Orocos::Log::Replay.open(ARGV[0] + "bb2.log", ARGV[0] + "waypoint_navigation.log" , ARGV[0] + "imu.log")
    end
    
    # uses timestamp when data was acquired
    log_replay.use_sample_time = true

    # Connect
    log_replay.camera_firewire_bb2.frame.connect_to     camera_bb2.frame_in
    camera_bb2.left_frame.connect_to                    visual_odometry.left_frame
    camera_bb2.right_frame.connect_to                   visual_odometry.right_frame
    log_replay.imu_stim300.orientation_samples_out.connect_to  extended_visual_odometry.pose_samples_imu
    visual_odometry.delta_pose_samples_out.connect_to 	   extended_visual_odometry.delta_pose_samples_in

#    log_replay.gps.pose_samples.connect_to              gps_heading2.gps_pose_samples
#    log_replay.gps_heading.pose_samples_out.connect_to  gps_heading2.gps_pose_samples
#    log_replay.gps_heading.pose_samples_out.connect_to  
    
    camera_bb2.left_frame.connect_to                    stereo_bb2.left_frame
    camera_bb2.right_frame.connect_to                   stereo_bb2.right_frame

    reader = log_replay.gps_heading.pose_samples_out.reader

    # Start
    camera_bb2.start
    visual_odometry.start
    extended_visual_odometry.start
#    gps_heading2.start
    stereo_bb2.start

    # Open the log replay widget
    control = Vizkit.control log_replay
    control.speed = 1
    
    Vizkit.exec
end
