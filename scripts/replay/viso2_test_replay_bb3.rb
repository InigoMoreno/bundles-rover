#!/usr/bin/env ruby

require 'orocos'
require 'rock/bundle'
require 'transformer/runtime'
require 'vizkit'
include Orocos

Bundles.initialize
Bundles.transformer.load_conf(Bundles.find_file('config', 'transforms_scripts.rb'))

Orocos::Process.run 'hdpr_unit_visual_odometry', 'hdpr_unit_bb3', 'hdpr_gps_heading' do

    camera_bb3 = TaskContext.get 'camera_bb3'
    Orocos.conf.apply(camera_bb3, ['default'], :override => true)
    camera_bb3.configure
    
    visual_odometry = TaskContext.get 'viso2'
    Orocos.conf.apply(visual_odometry, ['bumblebee3'], :override => true)
    Bundles.transformer.setup(visual_odometry)
    visual_odometry.configure
    
    gps_heading = TaskContext.get 'gps_heading'
    Orocos.conf.apply(gps_heading, ['default'], :override => true)
    gps_heading.configure
    
    stereo_bb3 = TaskContext.get 'stereo_bb3'
    Orocos.conf.apply(stereo_bb3, ['hdpr_bb3_left_right'], :override => true)
    stereo_bb3.configure

    # Connect the tasks to the logs
    if ARGV.size == 1 then
        log_replay = Orocos::Log::Replay.open(ARGV[0] + "bb3.log", ARGV[0] + "gps.log")
    end
    
    # uses timestamp when data was acquired
    log_replay.use_sample_time = true

    # Connect
    log_replay.camera_firewire_bb3.frame.connect_to     camera_bb3.frame_in
    camera_bb3.left_frame.connect_to                    visual_odometry.left_frame
    camera_bb3.right_frame.connect_to                   visual_odometry.right_frame
    log_replay.gps.pose_samples.connect_to              gps_heading.gps_pose_samples
    
    camera_bb3.left_frame.connect_to                    stereo_bb3.left_frame
    camera_bb3.right_frame.connect_to                   stereo_bb3.right_frame

    # Start
    camera_bb3.start
    visual_odometry.start
    gps_heading.start
    stereo_bb3.start

    # Open the log replay widget
    control = Vizkit.control log_replay
    control.speed = 1
    
    Vizkit.exec
end
